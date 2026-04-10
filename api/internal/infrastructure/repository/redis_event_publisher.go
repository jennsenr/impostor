package repository

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/redis/go-redis/v9"
)

type RedisEventPublisher struct {
	client *redis.Client
}

func NewRedisEventPublisher(client *redis.Client) *RedisEventPublisher {
	return &RedisEventPublisher{client: client}
}

// PublishGameUpdate publica un evento en el canal Pub/Sub de Redis
func (p *RedisEventPublisher) PublishGameUpdate(ctx context.Context, gameID string) error {
	channel := fmt.Sprintf("game_updates:%s", gameID)
	
	// Enviamos un mensaje estructurado
	msg := map[string]interface{}{
		"type":    "GAME_UPDATE",
		"game_id": gameID,
	}
	
	payload, _ := json.Marshal(msg)
	return p.client.Publish(ctx, channel, payload).Err()
}

// PublishPlayerEvent publica una notificación específica sobre un jugador (unirse, salir, desconexión)
func (p *RedisEventPublisher) PublishPlayerEvent(ctx context.Context, gameID string, eventType string, playerID string, name string, avatarID string) error {
	channel := fmt.Sprintf("game_updates:%s", gameID)
	
	msg := map[string]interface{}{
		"type":      "PLAYER_EVENT",
		"event":     eventType, // "LEFT", "DISCONNECTED", "RECONNECTED"
		"player_id": playerID,
		"name":      name,
		"avatar_id": avatarID,
	}
	
	payload, _ := json.Marshal(msg)
	return p.client.Publish(ctx, channel, payload).Err()
}
