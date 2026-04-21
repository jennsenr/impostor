package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jennsenr/impostor/api/internal/application/service"
	"github.com/jennsenr/impostor/api/internal/infrastructure/handler"
	"github.com/jennsenr/impostor/api/internal/infrastructure/repository"
	"github.com/jennsenr/impostor/api/internal/infrastructure/router"
	"github.com/jennsenr/impostor/api/internal/infrastructure/ws"
	"github.com/redis/go-redis/v9"
)

func main() {
	ctx := context.Background()

	// Configuración de Redis
	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		redisAddr = "localhost:6379"
	}

	rdb := redis.NewClient(&redis.Options{
		Addr: redisAddr,
	})

	// Verificar conexión con Redis
	if err := rdb.Ping(ctx).Err(); err != nil {
		log.Fatalf("No se pudo conectar a Redis en %s: %v", redisAddr, err)
	}
	log.Printf("Conectado a Redis en %s", redisAddr)

	// Asegurar que la carpeta pública existe
	publicDir := os.Getenv("PUBLIC_DIR_PATH")
	if publicDir == "" {
		publicDir = "public"
	}
	if err := os.MkdirAll(publicDir, 0755); err != nil {
		log.Fatalf("No se pudo crear la carpeta pública %s: %v", publicDir, err)
	}
	log.Printf("Carpeta pública lista en %s", publicDir)

	// Configuración de Repositorio de Palabras (JSON)
	wordsPath := os.Getenv("WORDS_FILE_PATH")
	if wordsPath == "" {
		wordsPath = "internal/infrastructure/data/words.json"
	}
	wordRepo, err := repository.NewJsonWordRepository(wordsPath)
	if err != nil {
		log.Fatalf("No se pudo cargar el repositorio de palabras: %v", err)
	}
	log.Printf("Repositorio de palabras cargado desde %s", wordsPath)

	// Inicializar componentes de Tiempo Real
	gameRepo := repository.NewRedisGameRepository(rdb)
	publisher := repository.NewRedisEventPublisher(rdb)

	gameSvc := service.NewGameService(gameRepo, wordRepo, publisher)
	hub := ws.NewHub(gameRepo, publisher, gameSvc, rdb)
	go hub.SubscribeToRedis(ctx) // Escuchar eventos de Redis Pub/Sub
	log.Printf("Sistema de notificaciones en tiempo real (Pub/Sub) iniciado")

	// Inyección de dependencias
	gameHandler := handler.NewGameHandler(gameSvc)
	wsHandler := handler.NewWSHandler(hub)

	// Configuración del servidor
	r := router.NewRouter(gameHandler, wsHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	srv := &http.Server{
		Addr:    ":" + port,
		Handler: r,
	}

	// Canal para recibir señales de interrupción
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		log.Printf("Servidor escuchando en el puerto %s", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Error al iniciar el servidor: %v", err)
		}
	}()

	// Esperar señal de salida
	<-quit
	log.Println("Apagando servidor...")

	// Timeout de 5 segundos para el apagado
	ctxShutdown, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctxShutdown); err != nil {
		log.Fatal("Server forced to shutdown:", err)
	}

	if err := rdb.Close(); err != nil {
		log.Printf("Error al cerrar Redis: %v", err)
	}

	log.Println("Servidor apagado correctamente")
}
