package test

import (
	"context"
	"fmt"
	"sync"

	"github.com/jennsenr/impostor/api/internal/domain/entity"
	"github.com/jennsenr/impostor/api/internal/domain/errs"
	"github.com/jennsenr/impostor/api/internal/domain/vo"
)

// InMemoryGameRepository es una implementación en memoria de la interfaz GameRepository para tests E2E y unitarios.
type InMemoryGameRepository struct {
	mu    sync.RWMutex
	games map[vo.GameID]*entity.Game
}

func NewInMemoryGameRepository() *InMemoryGameRepository {
	return &InMemoryGameRepository{
		games: make(map[vo.GameID]*entity.Game),
	}
}

func (r *InMemoryGameRepository) Save(ctx context.Context, game *entity.Game) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.games[game.ID] = game
	return nil
}

func (r *InMemoryGameRepository) GetByID(ctx context.Context, id vo.GameID) (*entity.Game, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	game, exists := r.games[id]
	if !exists {
		return nil, errs.ErrGameNotFound
	}
	return game, nil
}

func (r *InMemoryGameRepository) GetByCode(ctx context.Context, code string) (*entity.Game, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, game := range r.games {
		if game.Code == code {
			return game, nil
		}
	}
	return nil, errs.ErrGameNotFound
}

func (r *InMemoryGameRepository) Delete(ctx context.Context, id vo.GameID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	delete(r.games, id)
	return nil
}

// InMemoryWordRepository devuelve palabras fijas para tests predecibles.
type InMemoryWordRepository struct {
	words []*entity.Word
}

func NewInMemoryWordRepository() *InMemoryWordRepository {
	return &InMemoryWordRepository{
		words: []*entity.Word{
			{Text: "León", CategoryID: "animals"},
			{Text: "Gato", CategoryID: "animals"},
		},
	}
}

func (r *InMemoryWordRepository) GetRandomWord(ctx context.Context, categoryID vo.CategoryID, isJunior bool) (*entity.Word, error) {
	for _, w := range r.words {
		if w.CategoryID == categoryID {
			return w, nil
		}
	}
	return nil, fmt.Errorf("no words for category %s", categoryID)
}

func (r *InMemoryWordRepository) GetCategories(ctx context.Context) ([]vo.Category, error) {
	return vo.GetAvailableCategories(), nil
}

// InMemoryEventPublisher no hace nada o captura eventos para aserciones.
type InMemoryEventPublisher struct{}

func (p *InMemoryEventPublisher) PublishGameUpdate(ctx context.Context, gameID string) error {
	return nil
}

func (p *InMemoryEventPublisher) PublishPlayerEvent(ctx context.Context, gameID string, eventType string, playerID string, name string, avatarID string) error {
	return nil
}
