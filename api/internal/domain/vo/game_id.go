package vo

import "github.com/google/uuid"

type GameID string

func NewGameID() GameID {
	return GameID(uuid.New().String())
}

func (g GameID) String() string {
	return string(g)
}

func IsValidUUID(u string) bool {
	_, err := uuid.Parse(u)
	return err == nil
}
