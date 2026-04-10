package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jennsenr/impostor/api/internal/application/request"
	"github.com/jennsenr/impostor/api/internal/application/service"
	"github.com/jennsenr/impostor/api/internal/domain/entity"
	"github.com/jennsenr/impostor/api/internal/domain/errs"
)

type GameHandler struct {
	svc *service.GameService
}

func NewGameHandler(svc *service.GameService) *GameHandler {
	return &GameHandler{svc: svc}
}

// CreateGame maneja la creación de una nueva partida
func (h *GameHandler) CreateGame(c *gin.Context) {
	var req request.CreateGameRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "invalid_request", "message": err.Error()})
		return
	}

	game, err := h.svc.CreateGame(c.Request.Context(), req)
	if err != nil {
		mapDomainError(c, err)
		return
	}

	c.JSON(http.StatusCreated, game)
}

// JoinGame maneja la unión de un jugador a la partida
func (h *GameHandler) JoinGame(c *gin.Context) {
	gameID := c.Param("id")
	playerIDHeader := c.GetHeader("X-Player-ID")
	var req request.JoinGameRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "invalid_request", "message": err.Error()})
		return
	}

	game, err := h.svc.JoinGame(c.Request.Context(), gameID, req, playerIDHeader)
	if err != nil {
		mapDomainError(c, err)
		return
	}

	// Encontrar el ID del jugador que se acaba de unir o re-unir (por nombre)
	var playerID string
	for _, p := range game.Players {
		if p.Name == req.PlayerName {
			playerID = p.ID
			break
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"player_id": playerID,
		"game":      game.SanitizeForPlayer(playerID),
	})
}

// FinishAd finaliza la fase de anuncio
func (h *GameHandler) FinishAd(c *gin.Context) {
	gameID := c.Param("id")
	playerID := c.GetHeader("X-Player-ID")
	if playerID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"code": "unauthorized"})
		return
	}

	game, err := h.svc.FinishAd(c.Request.Context(), gameID, playerID)
	if err != nil {
		mapDomainError(c, err)
		return
	}

	c.JSON(http.StatusOK, game.SanitizeForPlayer(playerID))
}

// Rematch maneja el reinicio de una partida
func (h *GameHandler) Rematch(c *gin.Context) {
	gameID := c.Param("id")
	game, err := h.svc.Rematch(c.Request.Context(), gameID)
	if err != nil {
		mapDomainError(c, err)
		return
	}

	c.JSON(http.StatusOK, game.SanitizeForPlayer(c.GetHeader("X-Player-ID")))
}

// LeaveGame maneja la salida de un jugador de la partida
func (h *GameHandler) LeaveGame(c *gin.Context) {
	gameID := c.Param("id")
	playerID := c.GetHeader("X-Player-ID")
	if playerID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"code": "unauthorized"})
		return
	}

	err := h.svc.LeaveGame(c.Request.Context(), gameID, playerID)
	if err != nil {
		mapDomainError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "left"})
}

// GetGame devuelve el estado de la partida
func (h *GameHandler) GetGame(c *gin.Context) {
	gameID := c.Param("id")
	playerID := c.GetHeader("X-Player-ID")

	game, err := h.svc.GetGame(c.Request.Context(), gameID)
	if err != nil {
		mapDomainError(c, err)
		return
	}

	c.JSON(http.StatusOK, game.SanitizeForPlayer(playerID))
}

// UpdateSettings permite al host cambiar la configuración de la sala
func (h *GameHandler) UpdateSettings(c *gin.Context) {
	gameID := c.Param("id")
	hostID := c.GetHeader("X-Host-ID")
	if hostID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"code": "unauthorized"})
		return
	}
	var req request.UpdateSettingsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "invalid_request", "message": err.Error()})
		return
	}

	game, err := h.svc.UpdateSettings(c.Request.Context(), gameID, hostID, req)
	if err != nil {
		mapDomainError(c, err)
		return
	}

	c.JSON(http.StatusOK, game.SanitizeForPlayer(hostID))
}

// mapDomainError traduce los errores de dominio a códigos HTTP según la arquitectura
func mapDomainError(c *gin.Context, err error) {
	switch err {
	case errs.ErrGameNotFound:
		c.JSON(http.StatusNotFound, gin.H{"code": err.Error()})
	case errs.ErrPlayerNotFound:
		c.JSON(http.StatusNotFound, gin.H{"code": err.Error()})
	case errs.ErrPlayerAlreadyExists, errs.ErrNameAlreadyTaken, errs.ErrAvatarAlreadyTaken, errs.ErrGameAlreadyStarted, errs.ErrMinimumPlayersRequired, errs.ErrGameFull:
		c.JSON(http.StatusConflict, gin.H{"code": err.Error()})
	case errs.ErrInvalidStatus, errs.ErrNotHost, errs.ErrInvalidCategory:
		c.JSON(http.StatusBadRequest, gin.H{"code": err.Error()})
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"code": "internal_server_error"})
	}
}

// StartGame inicia la partida
func (h *GameHandler) StartGame(c *gin.Context) {
	gameID := c.Param("id")
	hostID := c.GetHeader("X-Host-ID")
	if hostID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"code": "unauthorized"})
		return
	}

	game, err := h.svc.StartGame(c.Request.Context(), gameID, hostID)
	if err != nil {
		mapDomainError(c, err)
		return
	}

	c.JSON(http.StatusOK, game.SanitizeForPlayer(hostID))
}

// ReadyPlayer marca al jugador como listo
func (h *GameHandler) ReadyPlayer(c *gin.Context) {
	gameID := c.Param("id")
	playerID := c.GetHeader("X-Player-ID")
	if playerID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"code": "unauthorized"})
		return
	}

	game, err := h.svc.ReadyPlayer(c.Request.Context(), gameID, playerID)
	if err != nil {
		mapDomainError(c, err)
		return
	}

	c.JSON(http.StatusOK, game.SanitizeForPlayer(c.GetHeader("X-Player-ID")))
}

// NextTurn avanza el turno
func (h *GameHandler) NextTurn(c *gin.Context) {
	gameID := c.Param("id")
	playerID := c.GetHeader("X-Player-ID")
	if playerID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"code": "unauthorized"})
		return
	}

	game, err := h.svc.NextTurn(c.Request.Context(), gameID, playerID)
	if err != nil {
		mapDomainError(c, err)
		return
	}

	c.JSON(http.StatusOK, game.SanitizeForPlayer(playerID))
}

// SubmitVote procesa un voto
func (h *GameHandler) SubmitVote(c *gin.Context) {
	gameID := c.Param("id")
	playerID := c.GetHeader("X-Player-ID")
	if playerID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"code": "unauthorized"})
		return
	}
	var req request.VoteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "invalid_request"})
		return
	}

	game, err := h.svc.SubmitVote(c.Request.Context(), gameID, playerID, req)
	if err != nil {
		mapDomainError(c, err)
		return
	}

	c.JSON(http.StatusOK, game.SanitizeForPlayer(playerID))
}

// SubmitDecision procesa la decisión de votar
func (h *GameHandler) SubmitDecision(c *gin.Context) {
	gameID := c.Param("id")
	playerID := c.GetHeader("X-Player-ID")
	if playerID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"code": "unauthorized"})
		return
	}
	var req request.DecisionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "invalid_request"})
		return
	}

	game, err := h.svc.SubmitDecision(c.Request.Context(), gameID, playerID, req)
	if err != nil {
		mapDomainError(c, err)
		return
	}

	c.JSON(http.StatusOK, game.SanitizeForPlayer(playerID))
}

// CalculateResults muestra los resultados de la votación
func (h *GameHandler) CalculateResults(c *gin.Context) {
	gameID := c.Param("id")
	results, err := h.svc.CalculateResults(c.Request.Context(), gameID)
	if err != nil {
		mapDomainError(c, err)
		return
	}
	// Sanitizar el estado de juego dentro de los resultados para ocultar datos sensibles
	var playerID string = c.GetHeader("X-Player-ID")
	if g, ok := results["game_state"].(*entity.Game); ok {
		results["game_state"] = g.SanitizeForPlayer(playerID)
	}

	c.JSON(http.StatusOK, results)
}

// GetCategories devuelve el catálogo de categorías
func (h *GameHandler) GetCategories(c *gin.Context) {
	categories, err := h.svc.GetCategories(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": "internal_error"})
		return
	}

	c.JSON(http.StatusOK, categories)
}

// RedirectToApp sirve una página HTML que redirecciona a la aplicación móvil
func (h *GameHandler) RedirectToApp(c *gin.Context) {
	code := c.Param("code")

	html := `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Abriendo Impostor...</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; background-color: #1a1a1a; color: white; text-align: center; }
        .btn { background-color: #6200ee; color: white; border: none; padding: 16px 32px; border-radius: 12px; font-weight: bold; text-decoration: none; margin-top: 24px; display: inline-block; }
    </style>
</head>
<body>
    <h1>¡Te han invitado a una partida!</h1>
    <p>Estamos abriendo la aplicación Impostor...</p>
    <a href="impostor://join?code=%s" class="btn">ABRIR APP MANUALMENTE</a>
    
    <script>
        const deepLink = "impostor://join?code=%s";
        window.location.href = deepLink;
        
        // Timer de seguridad por si la redirección automática falla
        setTimeout(() => {
            console.log("Redirección automática fallida, el usuario debe pulsar el botón");
        }, 2000);
    </script>
</body>
</html>
`
	c.Header("Content-Type", "text/html")
	c.String(200, html, code, code)
}

// NextRound avanza la partida a la siguiente fase
func (h *GameHandler) NextRound(c *gin.Context) {
	gameID := c.Param("id")
	playerID := c.GetHeader("X-Player-ID")
	if playerID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"code": "unauthorized"})
		return
	}

	game, err := h.svc.NextRound(c.Request.Context(), gameID, playerID)
	if err != nil {
		mapDomainError(c, err)
		return
	}
	c.JSON(http.StatusOK, game.SanitizeForPlayer(playerID))
}
