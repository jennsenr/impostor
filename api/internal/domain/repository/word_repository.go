package repository

import (
	"context"
	"github.com/jennsenr/impostor/api/internal/domain/entity"
	"github.com/jennsenr/impostor/api/internal/domain/vo"
)

type WordRepository interface {
	// GetRandomWord obtiene una palabra aleatoria filtrada por categoría y si es junior o no
	GetRandomWord(ctx context.Context, categoryID vo.CategoryID, isJunior bool, language vo.Language) (*entity.Word, error)

	// GetCategories obtiene todas las categorías disponibles
	GetCategories(ctx context.Context, language vo.Language) ([]vo.Category, error)
}
