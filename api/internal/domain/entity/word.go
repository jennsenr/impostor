package entity

import "github.com/jennsenr/impostor/api/internal/domain/vo"

type Word struct {
	Text       string        `json:"text"`
	TextEN     string        `json:"text_en,omitempty"`
	CategoryID vo.CategoryID `json:"category_id"`
	IsJunior   bool          `json:"is_junior"`
	ImageURL   string        `json:"image_url,omitempty"`
}

func NewWord(text string, textEN string, categoryID vo.CategoryID, isJunior bool, imageURL string) *Word {
	return &Word{
		Text:       text,
		TextEN:     textEN,
		CategoryID: categoryID,
		IsJunior:   isJunior,
		ImageURL:   imageURL,
	}
}

func (w Word) Localized(language vo.Language) *Word {
	localized := w
	if vo.NormalizeLanguage(string(language)) == vo.LanguageEnglish && localized.TextEN != "" {
		localized.Text = localized.TextEN
	}
	return &localized
}
