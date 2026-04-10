package handler

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/jennsenr/impostor/api/internal/infrastructure/ws"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // En producción, restringir a dominios permitidos
	},
}

type WSHandler struct {
	hub *ws.Hub
}

func NewWSHandler(hub *ws.Hub) *WSHandler {
	return &WSHandler{hub: hub}
}

// HandleWS gestiona la conexión WebSocket para una partida específica
func (h *WSHandler) HandleWS(c *gin.Context) {
	gameID := c.Param("id")
	playerID := c.Query("player_id")

	if playerID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "player_id is required"})
		return
	}

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("Error al upgradear conexión WS: %v", err)
		return
	}

	h.hub.Register(gameID, conn, playerID)

	defer func() {
		h.hub.Unregister(gameID, conn)
		_ = conn.Close()
	}()

	// Mantener la conexión abierta y escuchar mensajes de control (ping/pong)
	for {
		_, _, err := conn.ReadMessage()
		if err != nil {
			break
		}
	}
}
