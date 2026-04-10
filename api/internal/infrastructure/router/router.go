package router

import (
	"os"

	"github.com/gin-gonic/gin"
	"github.com/jennsenr/impostor/api/internal/infrastructure/handler"
)

// NewRouter configura las rutas del API usando Gin
func NewRouter(gameHandler *handler.GameHandler, wsHandler *handler.WSHandler) *gin.Engine {
	r := gin.Default()

	// CORS Middleware manual para evitar dependencias externas problemáticas
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With, X-Host-ID, X-Player-ID")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// Rutas de salud
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// Static Files (Imágenes de palabras Junior, etc.)
	publicPath := os.Getenv("PUBLIC_DIR_PATH")
	if publicPath == "" {
		publicPath = "public"
	}
	r.Static("/public", publicPath)

	// Redirección para Deep Links clicables
	r.GET("/join/:code", gameHandler.RedirectToApp)

	// API v1
	v1 := r.Group("/v1")
	{
		v1.GET("/categories", gameHandler.GetCategories)

		games := v1.Group("/games")
		{
			games.POST("", gameHandler.CreateGame)
			games.POST("/:id/join", gameHandler.JoinGame)
			games.POST("/:id/leave", gameHandler.LeaveGame)
			games.GET("/:id", gameHandler.GetGame)
			games.POST("/:id/start", gameHandler.StartGame)
			games.POST("/:id/ad-finished", gameHandler.FinishAd)
			games.POST("/:id/ready", gameHandler.ReadyPlayer)
			games.POST("/:id/next-turn", gameHandler.NextTurn)
			games.POST("/:id/vote", gameHandler.SubmitVote)
			games.POST("/:id/decision", gameHandler.SubmitDecision)
			games.GET("/:id/results", gameHandler.CalculateResults)
			games.POST("/:id/next-round", gameHandler.NextRound)
			games.PUT("/:id/settings", gameHandler.UpdateSettings)
			games.POST("/:id/rematch", gameHandler.Rematch)

			// WebSocket para notificaciones en tiempo real
			games.GET("/:id/ws", wsHandler.HandleWS)
		}
	}

	// Servir archivos estáticos para las imágenes de las palabras Junior
	r.Static("/assets", "./public/assets")

	return r
}
