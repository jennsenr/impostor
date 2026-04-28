package service

import (
	"context"
	"fmt"
	"sync"

	"github.com/google/uuid"
	"github.com/jennsenr/impostor/api/internal/application/request"
	"github.com/jennsenr/impostor/api/internal/domain/entity"
	"github.com/jennsenr/impostor/api/internal/domain/errs"
	"github.com/jennsenr/impostor/api/internal/domain/repository"
	"github.com/jennsenr/impostor/api/internal/domain/vo"
	"math/rand/v2"
)

type GameService struct {
	repo      repository.GameRepository
	wordRepo  repository.WordRepository
	publisher repository.EventPublisher
	mu        sync.Mutex
}

func NewGameService(repo repository.GameRepository, wordRepo repository.WordRepository, publisher repository.EventPublisher) *GameService {
	return &GameService{
		repo:      repo,
		wordRepo:  wordRepo,
		publisher: publisher,
	}
}

// CreateGame crea una nueva partida y añade al host como primer jugador
func (s *GameService) CreateGame(ctx context.Context, req request.CreateGameRequest) (*entity.Game, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if len(req.Categories) == 0 {
		return nil, errs.ErrInvalidCategory
	}

	// Convertir strings a CategoryIDs
	categoryIDs := make([]vo.CategoryID, len(req.Categories))
	for i, cat := range req.Categories {
		categoryIDs[i] = vo.CategoryID(cat)
	}

	gameID := vo.NewGameID()
	code := s.GenerateCode()
	hostID := uuid.New().String()

	settings := vo.NewSettings(
		categoryIDs,
		req.ImpostorCount,
		vo.NormalizeLanguage(req.Language),
		req.JuniorMode,
		req.SurvivalMode,
		req.QuestionsMode,
		req.TimerEnabled,
		req.TimerSeconds,
	)
	game := entity.NewGame(gameID, code, hostID, settings)

	host := entity.NewPlayer(hostID, req.HostName, vo.AvatarID(req.AvatarID))
	if _, err := game.Join(host); err != nil {
		return nil, err
	}

	if err := s.repo.Save(ctx, game); err != nil {
		return nil, err
	}

	return game, nil
}

// JoinGame añade un nuevo jugador a una partida existente
func (s *GameService) JoinGame(ctx context.Context, gameIDOrCode string, req request.JoinGameRequest, existingPlayerID string) (*entity.Game, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Intentar buscar por código primero si parece un código (6 dígitos)
	var game *entity.Game
	var err error

	if len(gameIDOrCode) == 4 {
		game, err = s.repo.GetByCode(ctx, gameIDOrCode)
	}

	// Si no se encontró por código o no era un código, intentar por ID
	if game == nil {
		game, err = s.repo.GetByID(ctx, vo.GameID(gameIDOrCode))
		if err != nil {
			return nil, err
		}
	}

	playerID := existingPlayerID
	if playerID == "" {
		playerID = uuid.New().String()
	}
	player := entity.NewPlayer(playerID, req.PlayerName, vo.AvatarID(req.AvatarID))

	isRejoin, err := game.Join(player)
	if err != nil {
		return nil, err
	}

	if err := s.repo.Save(ctx, game); err != nil {
		return nil, err
	}

	// Notificar evento de jugador (Unido o Reconectado)
	eventType := "JOINED"
	if isRejoin {
		eventType = "RECONNECTED"
	}
	_ = s.publisher.PublishPlayerEvent(ctx, string(game.ID), eventType, player.ID, player.Name, string(player.AvatarID))

	// Notificar actualización general
	_ = s.publisher.PublishGameUpdate(ctx, string(game.ID))

	return game, nil
}

// LeaveGame elimina a un jugador de la partida. Si no quedan jugadores, se borra la partida.
func (s *GameService) LeaveGame(ctx context.Context, gameID string, playerID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	game, err := s.repo.GetByID(ctx, vo.GameID(gameID))
	if err != nil {
		return err
	}

	return s.leaveGameLocked(ctx, game, gameID, playerID)
}

// LeaveDisconnectedPlayer convierte una desconexión prolongada en un abandono real.
// Si el jugador ya volvió a conectarse o la partida ya no existe, no hace nada.
func (s *GameService) LeaveDisconnectedPlayer(ctx context.Context, gameID string, playerID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	game, err := s.repo.GetByID(ctx, vo.GameID(gameID))
	if err != nil {
		if err == errs.ErrGameNotFound {
			return nil
		}
		return err
	}

	for _, p := range game.Players {
		if p.ID != playerID {
			continue
		}
		if p.IsConnected {
			return nil
		}
		return s.leaveGameLocked(ctx, game, gameID, playerID)
	}

	return nil
}

func (s *GameService) leaveGameLocked(ctx context.Context, game *entity.Game, gameID string, playerID string) error {
	if game == nil {
		return errs.ErrGameNotFound
	}

	// Capturar info del jugador antes de eliminarlo para la notificación
	var playerName, avatarID string
	for _, p := range game.Players {
		if p.ID == playerID {
			playerName = p.Name
			avatarID = string(p.AvatarID)
			break
		}
	}

	if err := game.Leave(playerID); err != nil {
		return err
	}

	if len(game.Players) == 0 {
		return s.repo.Delete(ctx, game.ID)
	}

	s.reconcileGameAfterLeave(game)

	if err := s.repo.Save(ctx, game); err != nil {
		return err
	}

	// Notificar que alguien ABANDONÓ (permanente)
	if playerName != "" {
		_ = s.publisher.PublishPlayerEvent(ctx, gameID, "LEFT", playerID, playerName, avatarID)
	}

	// Notificar actualización de estado
	_ = s.publisher.PublishGameUpdate(ctx, gameID)

	return nil
}

func (s *GameService) reconcileGameAfterLeave(game *entity.Game) {
	if game == nil || len(game.Players) == 0 {
		return
	}

	s.resolveWinnerAfterLeave(game)

	switch game.Status {
	case vo.StatusAdPhase:
		allDone := true
		for _, p := range game.Players {
			if !p.AdCompleted {
				allDone = false
				break
			}
		}
		if allDone {
			game.Status = vo.StatusReady
		}
	case vo.StatusReady:
		allReady := true
		for _, p := range game.Players {
			if !p.IsReady {
				allReady = false
				break
			}
		}
		if allReady {
			_ = game.Ready(game.Players[0].ID)
		}
	case vo.StatusDecision:
		allDecided := true
		votesForVoting := 0
		votesForAnotherRound := 0

		for _, p := range game.Players {
			if !p.IsAlive {
				continue
			}
			if !p.HasDecided {
				allDecided = false
				break
			}
			if p.WantsToVote {
				votesForVoting++
			} else {
				votesForAnotherRound++
			}
		}

		if allDecided {
			if votesForVoting > votesForAnotherRound {
				_ = game.SetStatus(vo.StatusVoting)
			} else {
				_ = game.SetStatus(vo.StatusPlaying)
			}
		}
	case vo.StatusVoting:
		allVoted := true
		for _, p := range game.Players {
			if p.IsAlive && !p.HasVoted {
				allVoted = false
				break
			}
		}
		if allVoted {
			_, _, _, _ = game.CalculateResults()
		}
	}
}

func (s *GameService) resolveWinnerAfterLeave(game *entity.Game) {
	if game == nil {
		return
	}

	switch game.Status {
	case vo.StatusWaiting, vo.StatusFinished, vo.StatusResult:
		return
	}

	impostorsAlive := 0
	civiliansAlive := 0
	for _, p := range game.Players {
		if !p.IsAlive {
			continue
		}
		if p.IsImpostor {
			impostorsAlive++
		} else {
			civiliansAlive++
		}
	}

	switch {
	case impostorsAlive == 0:
		game.Status = vo.StatusResult
		game.WinnerTeam = "civilians"
		game.ExpelledID = ""
	case civiliansAlive == 0:
		game.Status = vo.StatusResult
		game.WinnerTeam = "impostors"
		game.ExpelledID = ""
	}
}

// GetGame recupera el estado actual de una partida por ID o por código
func (s *GameService) GetGame(ctx context.Context, gameIDOrCode string) (*entity.Game, error) {
	// Intentar buscar por código si tiene 4 caracteres
	if len(gameIDOrCode) == 4 {
		game, err := s.repo.GetByCode(ctx, gameIDOrCode)
		if err == nil {
			return game, nil
		}
	}

	// Por defecto buscar por ID
	return s.repo.GetByID(ctx, vo.GameID(gameIDOrCode))
}

// UpdateSettings permite cambiar la configuración de la sala (solo por el host)
func (s *GameService) UpdateSettings(ctx context.Context, gameID string, hostID string, req request.UpdateSettingsRequest) (*entity.Game, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	game, err := s.repo.GetByID(ctx, vo.GameID(gameID))
	if err != nil {
		return nil, err
	}

	categoryIDs := make([]vo.CategoryID, len(req.Categories))
	for i, cat := range req.Categories {
		categoryIDs[i] = vo.CategoryID(cat)
	}

	newSettings := vo.NewSettings(
		categoryIDs,
		req.ImpostorCount,
		vo.NormalizeLanguage(req.Language),
		req.JuniorMode,
		req.SurvivalMode,
		req.QuestionsMode,
		req.TimerEnabled,
		req.TimerSeconds,
	)
	if err := game.UpdateSettings(hostID, newSettings); err != nil {
		return nil, err
	}

	if err := s.repo.Save(ctx, game); err != nil {
		return nil, err
	}

	_ = s.publisher.PublishGameUpdate(ctx, gameID)

	return game, nil
}

// StartGame inicia la partida seleccionando una palabra aleatoria según la categoría y modo
func (s *GameService) StartGame(ctx context.Context, gameID string, hostID string) (*entity.Game, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	game, err := s.repo.GetByID(ctx, vo.GameID(gameID))
	if err != nil {
		return nil, err
	}

	// Seleccionar una categoría aleatoria de las configuradas en la sala
	if len(game.Settings.CategoryIDs) == 0 {
		return nil, errs.ErrInvalidCategory
	}

	idx := rand.IntN(len(game.Settings.CategoryIDs))
	selectedCategoryID := game.Settings.CategoryIDs[idx]

	word, err := s.wordRepo.GetRandomWord(
		ctx,
		selectedCategoryID,
		game.Settings.JuniorMode,
		game.Settings.Language,
	)
	if err != nil {
		return nil, err
	}

	if err := game.Start(hostID, word); err != nil {
		return nil, err
	}

	if err := s.repo.Save(ctx, game); err != nil {
		return nil, err
	}

	_ = s.publisher.PublishGameUpdate(ctx, gameID)

	return game, nil
}

// ReadyPlayer marca a un jugador como listo
func (s *GameService) ReadyPlayer(ctx context.Context, gameID string, playerID string) (*entity.Game, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	game, err := s.repo.GetByID(ctx, vo.GameID(gameID))
	if err != nil {
		return nil, err
	}

	if err := game.Ready(playerID); err != nil {
		return nil, err
	}

	if err := s.repo.Save(ctx, game); err != nil {
		return nil, err
	}

	_ = s.publisher.PublishGameUpdate(ctx, gameID)

	return game, nil
}

// NextTurn avanza al siguiente jugador
func (s *GameService) NextTurn(ctx context.Context, gameID string, playerID string) (*entity.Game, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	game, err := s.repo.GetByID(ctx, vo.GameID(gameID))
	if err != nil {
		return nil, err
	}

	if game.GetCurrentTurnPlayerID() != playerID {
		return nil, errs.ErrInvalidStatus
	}

	if err := game.NextTurn(); err != nil {
		return nil, err
	}

	if err := s.repo.Save(ctx, game); err != nil {
		return nil, err
	}

	_ = s.publisher.PublishGameUpdate(ctx, gameID)

	return game, nil
}

// SubmitVote registra un voto de un jugador
func (s *GameService) SubmitVote(ctx context.Context, gameID string, voterID string, req request.VoteRequest) (*entity.Game, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	game, err := s.repo.GetByID(ctx, vo.GameID(gameID))
	if err != nil {
		return nil, err
	}

	if err := game.Vote(voterID, req.TargetID); err != nil {
		return nil, err
	}

	allVoted := true
	for _, p := range game.Players {
		if p.IsAlive && !p.HasVoted {
			allVoted = false
			break
		}
	}

	if allVoted {
		_, _, _, _ = game.CalculateResults()
	}

	if err := s.repo.Save(ctx, game); err != nil {
		return nil, err
	}

	_ = s.publisher.PublishGameUpdate(ctx, gameID)

	return game, nil
}

// SubmitDecision registra la decisión de votar o seguir
func (s *GameService) SubmitDecision(ctx context.Context, gameID string, playerID string, req request.DecisionRequest) (*entity.Game, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	game, err := s.repo.GetByID(ctx, vo.GameID(gameID))
	if err != nil {
		return nil, err
	}

	var currentPlayer *entity.Player
	for _, p := range game.Players {
		if p.ID == playerID {
			currentPlayer = p
			break
		}
	}

	if currentPlayer == nil || !currentPlayer.IsAlive {
		return nil, errs.ErrInvalidStatus
	}

	currentPlayer.HasDecided = true
	currentPlayer.WantsToVote = req.VoteToVoting

	allDecided := true
	votesForVoting := 0
	votesForAnotherRound := 0

	for _, p := range game.Players {
		if p.IsAlive {
			if !p.HasDecided {
				allDecided = false
				break
			}
			if p.WantsToVote {
				votesForVoting++
			} else {
				votesForAnotherRound++
			}
		}
	}

	if allDecided {
		if votesForVoting > votesForAnotherRound {
			game.SetStatus(vo.StatusVoting)
		} else {
			game.SetStatus(vo.StatusPlaying)
		}
	}

	if err := s.repo.Save(ctx, game); err != nil {
		return nil, err
	}

	_ = s.publisher.PublishGameUpdate(ctx, gameID)

	return game, nil
}

// FinishAd marks a specific player's ad as completed during the waiting phase
// or transitions the game state if in the dedicated AdPhase.
func (s *GameService) FinishAd(ctx context.Context, gameID string, playerID string) (*entity.Game, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	game, err := s.repo.GetByID(ctx, vo.GameID(gameID))
	if err != nil {
		return nil, err
	}

	if game.Status == vo.StatusWaiting || game.Status == vo.StatusAdPhase {
		if err := game.FinishPlayerAd(playerID); err != nil {
			return nil, err
		}
	} else {
		// En cualquier otro estado (si llegara el caso), solo ignorar o devolver error?
		// Mantenemos AdFinished por si acaso para otros estados legacy, pero AD_PHASE ahora es per-player.
		if err := game.AdFinished(); err != nil {
			return nil, err
		}
	}

	if err := s.repo.Save(ctx, game); err != nil {
		return nil, err
	}

	_ = s.publisher.PublishGameUpdate(ctx, gameID)

	return game, nil
}

// CalculateResults procesa la votación final
func (s *GameService) CalculateResults(ctx context.Context, gameID string) (map[string]interface{}, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	game, err := s.repo.GetByID(ctx, vo.GameID(gameID))
	if err != nil {
		return nil, err
	}

	expelledID, wasImpostor, gameOver, winnerTeam := game.CalculateResults()

	if err := s.repo.Save(ctx, game); err != nil {
		return nil, err
	}

	_ = s.publisher.PublishGameUpdate(ctx, gameID)

	return map[string]interface{}{
		"expelled_player_id": expelledID,
		"was_impostor":       wasImpostor,
		"game_over":          gameOver,
		"winner_team":        winnerTeam,
		"game_state":         game,
	}, nil
}

// GetCategories devuelve el catálogo de categorías disponibles
func (s *GameService) GetCategories(ctx context.Context, language vo.Language) ([]vo.Category, error) {
	return vo.GetAvailableCategories(language), nil
}

func (s *GameService) GenerateCode() string {
	// Generar un código de 4 caracteres alfanuméricos (A-Z, 0-9)
	const charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	b := make([]byte, 4)
	for i := range b {
		b[i] = charset[rand.IntN(len(charset))]
	}
	return string(b)
}

// Rematch reinicia un juego recién terminado y envía una nueva palabra
func (s *GameService) Rematch(ctx context.Context, gameID string) (*entity.Game, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	game, err := s.repo.GetByID(ctx, vo.GameID(gameID))
	if err != nil {
		return nil, err
	}

	// Rematch también debe elegir categoría aleatoria
	if len(game.Settings.CategoryIDs) == 0 {
		return nil, errs.ErrInvalidCategory
	}

	idx := rand.IntN(len(game.Settings.CategoryIDs))
	selectedCategoryID := game.Settings.CategoryIDs[idx]

	word, err := s.wordRepo.GetRandomWord(
		ctx,
		selectedCategoryID,
		game.Settings.JuniorMode,
		game.Settings.Language,
	)
	if err != nil {
		return nil, err
	}

	if err := game.Rematch(word.Text, word.ImageURL, word.CategoryID); err != nil {
		return nil, err
	}

	if err := s.repo.Save(ctx, game); err != nil {
		return nil, err
	}

	_ = s.publisher.PublishGameUpdate(ctx, gameID)

	return game, nil
}

// NextRound avanza la partida a la siguiente ronda tras un resultado intermedio
func (s *GameService) NextRound(ctx context.Context, gameID string, playerID string) (*entity.Game, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	game, err := s.repo.GetByID(ctx, vo.GameID(gameID))
	if err != nil {
		return nil, err
	}

	if game.Status != vo.StatusResult {
		return nil, fmt.Errorf("invalid status for next round: %s", game.Status)
	}

	if game.HostID != playerID {
		return nil, errs.ErrNotHost
	}

	nextStatus := vo.StatusPlaying
	if game.WinnerTeam != "" {
		nextStatus = vo.StatusFinished
	}

	if err := game.SetStatus(nextStatus); err != nil {
		return nil, err
	}

	if err := s.repo.Save(ctx, game); err != nil {
		return nil, err
	}

	_ = s.publisher.PublishGameUpdate(ctx, gameID)

	return game, nil
}
