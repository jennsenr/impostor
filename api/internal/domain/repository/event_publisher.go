package repository

import "context"

// EventPublisher define el contrato para enviar notificaciones en tiempo real
type EventPublisher interface {
	PublishGameUpdate(ctx context.Context, gameID string) error
	PublishPlayerEvent(ctx context.Context, gameID string, eventType string, playerID string, name string, avatarID string) error
}
