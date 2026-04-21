package vo

import "strings"

type Language string

const (
	LanguageSpanish Language = "es"
	LanguageEnglish Language = "en"
)

func NormalizeLanguage(raw string) Language {
	value := strings.TrimSpace(strings.ToLower(raw))
	if strings.HasPrefix(value, "en") {
		return LanguageEnglish
	}
	return LanguageSpanish
}
