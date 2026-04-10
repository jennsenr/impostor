package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/jennsenr/impostor/api/internal/domain/entity"
	"github.com/jennsenr/impostor/api/internal/domain/errs"
	"github.com/jennsenr/impostor/api/internal/domain/vo"
)

type RedisGameRepository struct {
	client *redis.Client
}

func NewRedisGameRepository(client *redis.Client) *RedisGameRepository {
	return &RedisGameRepository{client: client}
}

// Save persiste la partida en Redis con una expiración de 24 horas
func (r *RedisGameRepository) Save(ctx context.Context, game *entity.Game) error {
	data, err := json.Marshal(game)
	if err != nil {
		fmt.Printf("Error marshaling game: %v\n", err)
		return errs.ErrInternal
	}

	key := fmt.Sprintf("game:%s", game.ID)
	if err := r.client.Set(ctx, key, data, 24*time.Hour).Err(); err != nil {
		fmt.Printf("Error saving to Redis: %v\n", err)
		return errs.ErrInternal
	}

	// Secondary index for code: gamecode:<code> -> game_id
	codeKey := fmt.Sprintf("gamecode:%s", game.Code)
	if err := r.client.Set(ctx, codeKey, string(game.ID), 24*time.Hour).Err(); err != nil {
		fmt.Printf("Error saving code index to Redis: %v\n", err)
		return errs.ErrInternal
	}

	return nil
}

// GetByID recupera una partida de Redis por su ID
func (r *RedisGameRepository) GetByID(ctx context.Context, id vo.GameID) (*entity.Game, error) {
	key := fmt.Sprintf("game:%s", id)
	data, err := r.client.Get(ctx, key).Bytes()
	if err == redis.Nil {
		return nil, errs.ErrGameNotFound
	}
	if err != nil {
		fmt.Printf("Error getting from Redis: %v\n", err)
		return nil, errs.ErrInternal
	}

	var game entity.Game
	if err := json.Unmarshal(data, &game); err != nil {
		fmt.Printf("Error unmarshaling game: %v\n", err)
		return nil, errs.ErrInternal
	}

	return &game, nil
}

// GetByCode recupera una partida de Redis por su código de sala
func (r *RedisGameRepository) GetByCode(ctx context.Context, code string) (*entity.Game, error) {
	codeKey := fmt.Sprintf("gamecode:%s", code)
	gameID, err := r.client.Get(ctx, codeKey).Result()
	if err == redis.Nil {
		return nil, errs.ErrGameNotFound
	}
	if err != nil {
		fmt.Printf("Error getting code index from Redis: %v\n", err)
		return nil, errs.ErrInternal
	}

	return r.GetByID(ctx, vo.GameID(gameID))
}

// Delete elimina una partida de Redis y su índice por código
func (r *RedisGameRepository) Delete(ctx context.Context, id vo.GameID) error {
	// Para borrar el índice por código, primero necesitaríamos el juego para saber el código.
	// O podríamos borrar solo el ID. Dado que expira en 24h, el índice huérfano no es crítico.
	// Pero por limpieza, intentamos recuperarlo.
	game, err := r.GetByID(ctx, id)
	if err == nil {
		codeKey := fmt.Sprintf("gamecode:%s", game.Code)
		_ = r.client.Del(ctx, codeKey).Err()
	}

	key := fmt.Sprintf("game:%s", id)
	if err := r.client.Del(ctx, key).Err(); err != nil {
		fmt.Printf("Error deleting from Redis: %v\n", err)
		return errs.ErrInternal
	}
	return nil
}
