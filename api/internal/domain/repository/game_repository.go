package repository

import (
	"context"
	"github.com/jennsenr/impostor/api/internal/domain/entity"
	"github.com/jennsenr/impostor/api/internal/domain/vo"
)

type GameRepository interface {
	Save(ctx context.Context, game *entity.Game) error
	GetByID(ctx context.Context, id vo.GameID) (*entity.Game, error)
	GetByCode(ctx context.Context, code string) (*entity.Game, error)
	Delete(ctx context.Context, id vo.GameID) error
}
