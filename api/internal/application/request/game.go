package request

type CreateGameRequest struct {
	HostName     string   `json:"host_name" binding:"required"`
	AvatarID     string   `json:"avatar_id" binding:"required"`
	Categories   []string `json:"categories" binding:"required"`
	JuniorMode   bool     `json:"junior_mode"`
	SurvivalMode bool     `json:"survival_mode"`
	TimerEnabled bool     `json:"timer_enabled"`
	TimerSeconds int      `json:"timer_seconds"`
}

type JoinGameRequest struct {
	PlayerName string `json:"player_name" binding:"required"`
	AvatarID   string `json:"avatar_id" binding:"required"`
}

type UpdateSettingsRequest struct {
	Categories   []string `json:"categories" binding:"required"`
	JuniorMode   bool     `json:"junior_mode"`
	SurvivalMode bool     `json:"survival_mode"`
	TimerEnabled bool     `json:"timer_enabled"`
	TimerSeconds int      `json:"timer_seconds"`
}
