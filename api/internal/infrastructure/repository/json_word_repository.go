package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"math/rand/v2"
	"os"
	"sync"

	"github.com/jennsenr/impostor/api/internal/domain/entity"
	"github.com/jennsenr/impostor/api/internal/domain/errs"
	"github.com/jennsenr/impostor/api/internal/domain/vo"
)

type JsonWordRepository struct {
	words []entity.Word
	mu    sync.RWMutex
}

// NewJsonWordRepository carga el dataset de palabras desde un archivo JSON
func NewJsonWordRepository(filePath string) (*JsonWordRepository, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("could not read words file: %w", err)
	}

	var words []entity.Word
	if err := json.Unmarshal(data, &words); err != nil {
		return nil, fmt.Errorf("could not unmarshal words: %w", err)
	}

	return &JsonWordRepository{words: words}, nil
}

// GetRandomWord filtra las palabras por categoría y modo junior, y devuelve una al azar
func (r *JsonWordRepository) GetRandomWord(ctx context.Context, categoryID vo.CategoryID, isJunior bool, language vo.Language) (*entity.Word, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var filtered []entity.Word
	for _, w := range r.words {
		if w.CategoryID == categoryID && w.IsJunior == isJunior {
			filtered = append(filtered, w)
		}
	}

	if len(filtered) == 0 {
		fmt.Printf("No words found for category %s (Junior: %v)\n", categoryID, isJunior)
		return nil, errs.ErrInternal
	}

	idx := rand.IntN(len(filtered))
	return filtered[idx].Localized(language), nil
}

// GetCategories devuelve las categorías disponibles filtradas por el catálogo del dominio
func (r *JsonWordRepository) GetCategories(ctx context.Context, language vo.Language) ([]vo.Category, error) {
	return vo.GetAvailableCategories(language), nil
}
