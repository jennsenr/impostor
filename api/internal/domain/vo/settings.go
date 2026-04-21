package vo

type Settings struct {
	CategoryIDs   []CategoryID `json:"category_ids"`
	ImpostorCount int          `json:"impostor_count"`
	Language      Language     `json:"language"`
	JuniorMode    bool         `json:"junior_mode"`
	TimerEnabled  bool         `json:"timer_enabled"`
	TimerSeconds  int          `json:"timer_seconds"`
	SurvivalMode  bool         `json:"survival_mode"`
	QuestionsMode bool         `json:"questions_mode"`
}

func NewSettings(categoryIDs []CategoryID, impostorCount int, language Language, juniorMode, survivalMode, questionsMode, timerEnabled bool, timerSeconds int) Settings {
	if impostorCount < 1 {
		impostorCount = 1
	}

	return Settings{
		CategoryIDs:   categoryIDs,
		ImpostorCount: impostorCount,
		Language:      NormalizeLanguage(string(language)),
		JuniorMode:    juniorMode,
		TimerEnabled:  timerEnabled,
		TimerSeconds:  timerSeconds,
		SurvivalMode:  survivalMode,
		QuestionsMode: questionsMode,
	}
}
