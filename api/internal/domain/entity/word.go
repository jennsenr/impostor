package entity

import "github.com/jennsenr/impostor/api/internal/domain/vo"

type Word struct {
	Text       string        `json:"text"`
	CategoryID vo.CategoryID `json:"category_id"`
	IsJunior   bool          `json:"is_junior"`
	ImageURL   string        `json:"image_url,omitempty"`
}

func NewWord(text string, categoryID vo.CategoryID, isJunior bool, imageURL string) *Word {
	return &Word{
		Text:       text,
		CategoryID: categoryID,
		IsJunior:   isJunior,
		ImageURL:   imageURL,
	}
}
