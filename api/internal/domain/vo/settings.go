package vo

type Settings struct {
	CategoryIDs   []CategoryID `json:"category_ids"`
	JuniorMode    bool         `json:"junior_mode"`
	TimerEnabled  bool         `json:"timer_enabled"`
	TimerSeconds  int          `json:"timer_seconds"`
	SurvivalMode  bool         `json:"survival_mode"`
}

func NewSettings(categoryIDs []CategoryID, juniorMode, survivalMode, timerEnabled bool, timerSeconds int) Settings {
	return Settings{
		CategoryIDs:   categoryIDs,
		JuniorMode:    juniorMode,
		TimerEnabled:  timerEnabled,
		TimerSeconds:  timerSeconds,
		SurvivalMode:  survivalMode,
	}
}
