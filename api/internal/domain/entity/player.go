package entity

import "github.com/jennsenr/impostor/api/internal/domain/vo"

type Player struct {
	ID           string      `json:"id"`
	Name         string      `json:"name"`
	AvatarID     vo.AvatarID `json:"avatar_id"`
	IsImpostor   bool        `json:"is_impostor"`
	IsAlive      bool        `json:"is_alive"`
	IsConnected  bool        `json:"is_connected"`
	IsReady      bool        `json:"is_ready"`
	HasVoted     bool        `json:"has_voted"`
	HasDecided   bool        `json:"has_decided"`
	WantsToVote  bool        `json:"wants_to_vote"`
	VoteTargetID string      `json:"vote_target_id"`
	OrderIndex   int         `json:"order_index"`
	AdCompleted  bool        `json:"ad_completed"`
}

func NewPlayer(id, name string, avatarID vo.AvatarID) *Player {
	return &Player{
		ID:          id,
		Name:        name,
		AvatarID:    avatarID,
		IsAlive:     true,
		IsConnected: true, // Assuming a player is connected when they are created/join
		IsReady:     false,
		HasVoted:    false,
		HasDecided:  false,
		WantsToVote: false,
		OrderIndex:  0,
		AdCompleted: false,
	}
}
