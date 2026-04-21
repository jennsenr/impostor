package ws

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/jennsenr/impostor/api/internal/domain/entity"
	"github.com/jennsenr/impostor/api/internal/domain/repository"
	"github.com/jennsenr/impostor/api/internal/domain/vo"
	"github.com/redis/go-redis/v9"
)

const autoLeaveAfterDisconnect = 5 * time.Second

type DisconnectLeaveService interface {
	LeaveDisconnectedPlayer(ctx context.Context, gameID string, playerID string) error
}

type Hub struct {
	gameRepo         repository.GameRepository
	publisher        repository.EventPublisher
	leaveService     DisconnectLeaveService
	rdb              *redis.Client
	clients          map[string]map[*websocket.Conn]string // gameID -> conn -> playerID
	disconnectTimers map[string]map[string]*time.Timer
	mu               sync.RWMutex
}

func NewHub(gameRepo repository.GameRepository, publisher repository.EventPublisher, leaveService DisconnectLeaveService, rdb *redis.Client) *Hub {
	return &Hub{
		gameRepo:         gameRepo,
		publisher:        publisher,
		leaveService:     leaveService,
		rdb:              rdb,
		clients:          make(map[string]map[*websocket.Conn]string),
		disconnectTimers: make(map[string]map[string]*time.Timer),
	}
}

// SubscribeToRedis escucha los eventos de actualización de partidas en Redis
func (h *Hub) SubscribeToRedis(ctx context.Context) {
	pubsub := h.rdb.PSubscribe(ctx, "game_updates:*")
	defer pubsub.Close()

	ch := pubsub.Channel()
	for msg := range ch {
		var payload map[string]interface{}
		if err := json.Unmarshal([]byte(msg.Payload), &payload); err != nil {
			log.Printf("Error unmarshaling Redis event: %v", err)
			continue
		}

		msgType, _ := payload["type"].(string)
		gameID, _ := payload["game_id"].(string)

		if gameID == "" {
			// El patrón es "game_updates:{gameID}"
			fmt.Sscanf(msg.Channel, "game_updates:%s", &gameID)
		}

		log.Printf("Redis event received: %s for game: %s", msgType, gameID)

		switch msgType {
		case "PLAYER_EVENT":
			// Reenviar el evento tal cual a los clientes conectados a esa partida
			h.broadcastRaw(ctx, gameID, []byte(msg.Payload))
		case "GAME_UPDATE":
			h.broadcastGameUpdate(ctx, gameID)
		default:
			// Fallback para mensajes antiguos (solo gameID) o no tipados
			h.broadcastGameUpdate(ctx, gameID)
		}
	}
}

// Register añade una nueva conexión WebSocket para una partida con el ID del jugador
func (h *Hub) Register(gameID string, conn *websocket.Conn, playerID string) {
	h.mu.Lock()
	if _, ok := h.clients[gameID]; !ok {
		h.clients[gameID] = make(map[*websocket.Conn]string)
	}
	h.clients[gameID][conn] = playerID
	h.mu.Unlock()

	h.cancelDisconnectTimer(gameID, playerID)

	// Actualizar estado de conexión en la entidad
	ctx := context.Background()
	game, err := h.gameRepo.GetByID(ctx, vo.GameID(gameID))
	if err == nil {
		if changed := game.SetPlayerConnectivity(playerID, true); changed {
			_ = h.gameRepo.Save(ctx, game)
			playerName, avatarID := h.findPlayerDetails(game, playerID)
			if playerName != "" {
				_ = h.publisher.PublishPlayerEvent(ctx, gameID, "RECONNECTED", playerID, playerName, avatarID)
			}
			h.broadcastGameUpdate(ctx, gameID)
		}
	}

	log.Printf("Player %s registered on WS for game %s", playerID, gameID)
}

// Unregister elimina una conexión WebSocket y notifica la desconexión
func (h *Hub) Unregister(gameID string, conn *websocket.Conn) {
	h.mu.Lock()
	playerID, exists := h.clients[gameID][conn]
	if exists {
		delete(h.clients[gameID], conn)
		if len(h.clients[gameID]) == 0 {
			delete(h.clients, gameID)
		}
	}
	h.mu.Unlock()

	if exists {
		ctx := context.Background()
		game, err := h.gameRepo.GetByID(ctx, vo.GameID(gameID))
		if err == nil {
			// Cambiar estado a desconectado
			if changed := game.SetPlayerConnectivity(playerID, false); changed {
				_ = h.gameRepo.Save(ctx, game)
				playerName, avatarID := h.findPlayerDetails(game, playerID)
				if playerName != "" {
					_ = h.publisher.PublishPlayerEvent(ctx, gameID, "DISCONNECTED", playerID, playerName, avatarID)
				}
				h.broadcastGameUpdate(ctx, gameID)
				h.scheduleDisconnectLeave(gameID, playerID)
			}
		}
	}
}

func (h *Hub) findPlayerDetails(game *entity.Game, playerID string) (string, string) {
	if game == nil {
		return "", ""
	}
	for _, player := range game.Players {
		if player.ID == playerID {
			return player.Name, string(player.AvatarID)
		}
	}
	return "", ""
}

func (h *Hub) scheduleDisconnectLeave(gameID, playerID string) {
	h.cancelDisconnectTimer(gameID, playerID)

	timer := time.AfterFunc(autoLeaveAfterDisconnect, func() {
		if h.leaveService != nil {
			if err := h.leaveService.LeaveDisconnectedPlayer(context.Background(), gameID, playerID); err != nil {
				log.Printf("Error auto-removing disconnected player %s from game %s: %v", playerID, gameID, err)
			}
		}
		h.clearDisconnectTimer(gameID, playerID)
	})

	h.mu.Lock()
	if _, ok := h.disconnectTimers[gameID]; !ok {
		h.disconnectTimers[gameID] = make(map[string]*time.Timer)
	}
	h.disconnectTimers[gameID][playerID] = timer
	h.mu.Unlock()
}

func (h *Hub) cancelDisconnectTimer(gameID, playerID string) {
	h.mu.Lock()
	defer h.mu.Unlock()

	gameTimers, ok := h.disconnectTimers[gameID]
	if !ok {
		return
	}

	timer, ok := gameTimers[playerID]
	if !ok {
		return
	}

	timer.Stop()
	delete(gameTimers, playerID)
	if len(gameTimers) == 0 {
		delete(h.disconnectTimers, gameID)
	}
}

func (h *Hub) clearDisconnectTimer(gameID, playerID string) {
	h.mu.Lock()
	defer h.mu.Unlock()

	gameTimers, ok := h.disconnectTimers[gameID]
	if !ok {
		return
	}

	delete(gameTimers, playerID)
	if len(gameTimers) == 0 {
		delete(h.disconnectTimers, gameID)
	}
}

// broadcastRaw envía un mensaje pre-formateado a todos los clientes de una partida
func (h *Hub) broadcastRaw(ctx context.Context, gameID string, payload []byte) {
	h.mu.RLock()
	conns, ok := h.clients[gameID]
	if !ok {
		h.mu.RUnlock()
		return
	}

	targets := make([]*websocket.Conn, 0, len(conns))
	for c := range conns {
		targets = append(targets, c)
	}
	h.mu.RUnlock()

	for _, conn := range targets {
		if err := conn.WriteMessage(websocket.TextMessage, payload); err != nil {
			// El error se manejará en el siguiente ciclo o por el defer de la conexión
			_ = conn.Close()
		}
	}
}

// broadcastGameUpdate obtiene el estado actual de la partida y lo envía de forma personalizada
func (h *Hub) broadcastGameUpdate(ctx context.Context, gameID string) {
	gameBase, err := h.gameRepo.GetByID(ctx, vo.GameID(gameID))
	if err != nil {
		log.Printf("Error al recuperar partida %s para broadcast: %v", gameID, err)
		return
	}

	h.mu.RLock()
	conns, ok := h.clients[gameID]
	if !ok {
		h.mu.RUnlock()
		return
	}

	// Copiar mapeo de conexiones para iterar fuera del lock
	targets := make(map[*websocket.Conn]string)
	for c, pid := range conns {
		targets[c] = pid
	}
	h.mu.RUnlock()

	for conn, playerID := range targets {
		// Personalizar payload para cada jugador según el estado de la partida.
		gameSanitized := gameBase.SanitizeForPlayer(playerID)

		msg := map[string]interface{}{
			"type":    "GAME_UPDATE",
			"game_id": gameID,
			"payload": gameSanitized,
		}

		payload, _ := json.Marshal(msg)
		if err := conn.WriteMessage(websocket.TextMessage, payload); err != nil {
			log.Printf("Error enviando WS a cliente %s: %v", playerID, err)
			_ = conn.Close()
		}
	}
}
