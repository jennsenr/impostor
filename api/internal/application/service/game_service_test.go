package service

import (
	"context"
	"testing"

	"github.com/jennsenr/impostor/api/internal/application/request"
	"github.com/jennsenr/impostor/api/internal/domain/entity"
	"github.com/jennsenr/impostor/api/internal/domain/vo"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// -- Mocks --

type GameRepoMock struct{ mock.Mock }

func (m *GameRepoMock) Save(ctx context.Context, game *entity.Game) error {
	return m.Called(ctx, game).Error(0)
}

func (m *GameRepoMock) GetByID(ctx context.Context, id vo.GameID) (*entity.Game, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entity.Game), args.Error(1)
}

func (m *GameRepoMock) GetByCode(ctx context.Context, code string) (*entity.Game, error) {
	args := m.Called(ctx, code)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entity.Game), args.Error(1)
}

func (m *GameRepoMock) Delete(ctx context.Context, id vo.GameID) error {
	return m.Called(ctx, id).Error(0)
}

type WordRepoMock struct{ mock.Mock }

func (m *WordRepoMock) GetRandomWord(ctx context.Context, categoryID vo.CategoryID, isJunior bool, language vo.Language) (*entity.Word, error) {
	args := m.Called(ctx, categoryID, isJunior, language)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entity.Word), args.Error(1)
}

func (m *WordRepoMock) GetCategories(ctx context.Context, language vo.Language) ([]vo.Category, error) {
	args := m.Called(ctx, language)
	return args.Get(0).([]vo.Category), args.Error(1)
}

type EventPublisherMock struct{ mock.Mock }

func (m *EventPublisherMock) PublishGameUpdate(ctx context.Context, gameID string) error {
	return m.Called(ctx, gameID).Error(0)
}

func (m *EventPublisherMock) PublishPlayerEvent(ctx context.Context, gameID string, eventType string, playerID string, name string, avatarID string) error {
	return m.Called(ctx, gameID, eventType, playerID, name, avatarID).Error(0)
}

// -- Tests --

func TestGameService_CreateGame(t *testing.T) {
	repo := new(GameRepoMock)
	wordRepo := new(WordRepoMock)
	pub := new(EventPublisherMock)
	svc := NewGameService(repo, wordRepo, pub)

	req := request.CreateGameRequest{
		HostName:      "Host",
		AvatarID:      "a1",
		Categories:    []string{"animals"},
		ImpostorCount: 1,
		JuniorMode:    false,
		SurvivalMode:  false,
	}

	repo.On("Save", mock.Anything, mock.AnythingOfType("*entity.Game")).Return(nil)

	game, err := svc.CreateGame(context.Background(), req)

	assert.NoError(t, err)
	assert.NotNil(t, game)
	assert.Equal(t, "Host", game.Players[0].Name)
	repo.AssertExpectations(t)
}

func TestGameService_JoinGame(t *testing.T) {
	repo := new(GameRepoMock)
	pub := new(EventPublisherMock)
	svc := NewGameService(repo, nil, pub)

	game := entity.NewGame("g1", "1234", "h", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
	repo.On("GetByID", mock.Anything, vo.GameID("g1")).Return(game, nil)
	repo.On("Save", mock.Anything, game).Return(nil)
	pub.On("PublishGameUpdate", mock.Anything, "g1").Return(nil)
	pub.On("PublishPlayerEvent", mock.Anything, "g1", "JOINED", mock.Anything, "P2", "a2").Return(nil)

	req := request.JoinGameRequest{
		PlayerName: "P2",
		AvatarID:   "a2",
	}

	updatedGame, err := svc.JoinGame(context.Background(), "g1", req, "")

	assert.NoError(t, err)
	assert.Len(t, updatedGame.Players, 1)
	assert.Equal(t, "P2", updatedGame.Players[0].Name)
	repo.AssertExpectations(t)
	pub.AssertExpectations(t)
}

func TestGameService_StartGame(t *testing.T) {
	repo := new(GameRepoMock)
	wordRepo := new(WordRepoMock)
	pub := new(EventPublisherMock)
	svc := NewGameService(repo, wordRepo, pub)

	game := entity.NewGame("g1", "123456", "host-1", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
	h := entity.NewPlayer("host-1", "H", "a1")
	h.AdCompleted = true
	p2 := entity.NewPlayer("p2", "P2", "a2")
	p2.AdCompleted = true
	p3 := entity.NewPlayer("p3", "P3", "a3")
	p3.AdCompleted = true

	_, _ = game.Join(h)
	_, _ = game.Join(p2)
	_, _ = game.Join(p3)

	word := &entity.Word{Text: "Lion"}

	repo.On("GetByID", mock.Anything, vo.GameID("g1")).Return(game, nil)
	wordRepo.On("GetRandomWord", mock.Anything, vo.CategoryID("animals"), false, vo.LanguageSpanish).Return(word, nil)
	repo.On("Save", mock.Anything, game).Return(nil)
	pub.On("PublishGameUpdate", mock.Anything, "g1").Return(nil)

	startedGame, err := svc.StartGame(context.Background(), "g1", "host-1")

	assert.NoError(t, err)
	assert.Equal(t, vo.StatusAdPhase, startedGame.Status)
	assert.Equal(t, "Lion", startedGame.Word)
	repo.AssertExpectations(t)
	wordRepo.AssertExpectations(t)
}

func TestGameService_ReadyPlayer(t *testing.T) {
	repo := new(GameRepoMock)
	pub := new(EventPublisherMock)
	svc := NewGameService(repo, nil, pub)

	game := entity.NewGame("g1", "123456", "h-1", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
	_, _ = game.Join(entity.NewPlayer("p1", "P1", "a1"))
	game.Status = vo.StatusReady

	repo.On("GetByID", mock.Anything, vo.GameID("g1")).Return(game, nil)
	repo.On("Save", mock.Anything, game).Return(nil)
	pub.On("PublishGameUpdate", mock.Anything, "g1").Return(nil)

	res, err := svc.ReadyPlayer(context.Background(), "g1", "p1")
	assert.NoError(t, err)
	assert.True(t, res.Players[0].IsReady)
}

func TestGameService_CalculateResults(t *testing.T) {
	repo := new(GameRepoMock)
	pub := new(EventPublisherMock)
	svc := NewGameService(repo, nil, pub)

	game := entity.NewGame("g1", "123456", "h-1", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
	p1 := entity.NewPlayer("p1", "P1", "a1")
	p2 := entity.NewPlayer("p2", "P2", "a2")
	_, _ = game.Join(p1)
	_, _ = game.Join(p2)
	p1.IsAlive, p2.IsAlive = true, true

	game.Status = vo.StatusVoting
	p1.HasVoted = true
	p1.VoteTargetID = "p2"
	p2.HasVoted = true
	p2.VoteTargetID = "p1" // Empate

	repo.On("GetByID", mock.Anything, vo.GameID("g1")).Return(game, nil)
	repo.On("Save", mock.Anything, game).Return(nil)
	pub.On("PublishGameUpdate", mock.Anything, "g1").Return(nil)

	results, err := svc.CalculateResults(context.Background(), "g1")
	assert.NoError(t, err)
	assert.Empty(t, results["expelled_player_id"])
	assert.Equal(t, vo.StatusResult, game.Status)
}

func TestGameService_NextRound_FinishesGameAfterFinalVoteResult(t *testing.T) {
	repo := new(GameRepoMock)
	pub := new(EventPublisherMock)
	svc := NewGameService(repo, nil, pub)

	game := entity.NewGame("g1", "123456", "h-1", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
	_, _ = game.Join(entity.NewPlayer("p1", "P1", "a1"))
	_, _ = game.Join(entity.NewPlayer("p2", "P2", "a2"))
	game.Status = vo.StatusResult
	game.WinnerTeam = "impostors"

	repo.On("GetByID", mock.Anything, vo.GameID("g1")).Return(game, nil)
	repo.On("Save", mock.Anything, game).Return(nil)
	pub.On("PublishGameUpdate", mock.Anything, "g1").Return(nil)

	res, err := svc.NextRound(context.Background(), "g1", "h-1")
	assert.NoError(t, err)
	assert.Equal(t, vo.StatusFinished, res.Status)
}

func TestGameService_NextTurn(t *testing.T) {
	repo := new(GameRepoMock)
	pub := new(EventPublisherMock)
	svc := NewGameService(repo, nil, pub)

	game := entity.NewGame("g1", "123456", "h-1", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
	_, _ = game.Join(entity.NewPlayer("p1", "P1", "a1"))
	_, _ = game.Join(entity.NewPlayer("p2", "P2", "a2"))
	game.Status = vo.StatusPlaying
	game.Players[0].IsAlive = true
	game.Players[1].IsAlive = true

	repo.On("GetByID", mock.Anything, vo.GameID("g1")).Return(game, nil)
	repo.On("Save", mock.Anything, game).Return(nil)
	pub.On("PublishGameUpdate", mock.Anything, "g1").Return(nil)

	res, err := svc.NextTurn(context.Background(), "g1", "p1")
	assert.NoError(t, err)
	assert.Equal(t, 1, res.CurrentTurnIndex)
}

func TestGameService_SubmitVote(t *testing.T) {
	repo := new(GameRepoMock)
	pub := new(EventPublisherMock)
	svc := NewGameService(repo, nil, pub)

	game := entity.NewGame("g1", "123456", "h-1", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
	_, _ = game.Join(entity.NewPlayer("p1", "P1", "a1"))
	_, _ = game.Join(entity.NewPlayer("p2", "P2", "a2"))
	game.Status = vo.StatusVoting
	game.Players[0].IsAlive = true
	game.Players[1].IsAlive = true

	repo.On("GetByID", mock.Anything, vo.GameID("g1")).Return(game, nil)
	repo.On("Save", mock.Anything, game).Return(nil)
	pub.On("PublishGameUpdate", mock.Anything, "g1").Return(nil)

	req := request.VoteRequest{TargetID: "p2"}
	res, err := svc.SubmitVote(context.Background(), "g1", "p1", req)
	assert.NoError(t, err)
	assert.True(t, res.Players[0].HasVoted)
}

func TestGameService_GenerateCode(t *testing.T) {
	svc := NewGameService(nil, nil, nil)

	t.Run("Generates 4-digit code", func(t *testing.T) {
		code := svc.GenerateCode()
		assert.Len(t, code, 4)
		// Ensure it's numeric
		assert.Regexp(t, "^[ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789]{4}$", code)
	})
}

func TestGameService_LeaveGame(t *testing.T) {
	t.Run("Deletes game when last player leaves", func(t *testing.T) {
		repo := new(GameRepoMock)
		pub := new(EventPublisherMock)
		svc := NewGameService(repo, nil, pub)

		game := entity.NewGame("g1", "123456", "p1", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
		_, _ = game.Join(entity.NewPlayer("p1", "P1", "a1"))

		repo.On("GetByID", mock.Anything, vo.GameID("g1")).Return(game, nil).Once()
		repo.On("Delete", mock.Anything, vo.GameID("g1")).Return(nil).Once()

		err := svc.LeaveGame(context.Background(), "g1", "p1")
		assert.NoError(t, err)
		repo.AssertExpectations(t)
		pub.AssertExpectations(t)
	})

	t.Run("Removes player but keeps game if players remain", func(t *testing.T) {
		repo := new(GameRepoMock)
		pub := new(EventPublisherMock)
		svc := NewGameService(repo, nil, pub)

		game := entity.NewGame("g2", "123456", "p1", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
		_, _ = game.Join(entity.NewPlayer("p1", "P1", "a1"))
		_, _ = game.Join(entity.NewPlayer("p2", "P2", "a2"))

		repo.On("GetByID", mock.Anything, vo.GameID("g2")).Return(game, nil).Once()
		repo.On("Save", mock.Anything, mock.AnythingOfType("*entity.Game")).Return(nil).Once()
		pub.On("PublishGameUpdate", mock.Anything, "g2").Return(nil).Once()
		pub.On("PublishPlayerEvent", mock.Anything, "g2", "LEFT", "p2", "P2", "a2").Return(nil).Once()

		err := svc.LeaveGame(context.Background(), "g2", "p2")
		assert.NoError(t, err)
		assert.Len(t, game.Players, 1)
		repo.AssertExpectations(t)
		pub.AssertExpectations(t)
	})

	t.Run("Reconciles pending decision when undecided player leaves", func(t *testing.T) {
		repo := new(GameRepoMock)
		pub := new(EventPublisherMock)
		svc := NewGameService(repo, nil, pub)

		game := entity.NewGame("g3", "123456", "p1", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
		p1 := entity.NewPlayer("p1", "P1", "a1")
		p2 := entity.NewPlayer("p2", "P2", "a2")
		p3 := entity.NewPlayer("p3", "P3", "a3")
		p4 := entity.NewPlayer("p4", "P4", "a4")
		_, _ = game.Join(p1)
		_, _ = game.Join(p2)
		_, _ = game.Join(p3)
		_, _ = game.Join(p4)
		game.Status = vo.StatusDecision
		p1.IsImpostor = true
		p1.HasDecided = true
		p1.WantsToVote = true
		p2.HasDecided = true
		p2.WantsToVote = true
		p3.HasDecided = true
		p3.WantsToVote = false

		repo.On("GetByID", mock.Anything, vo.GameID("g3")).Return(game, nil).Once()
		repo.On("Save", mock.Anything, mock.AnythingOfType("*entity.Game")).Return(nil).Once()
		pub.On("PublishGameUpdate", mock.Anything, "g3").Return(nil).Once()
		pub.On("PublishPlayerEvent", mock.Anything, "g3", "LEFT", "p4", "P4", "a4").Return(nil).Once()

		err := svc.LeaveGame(context.Background(), "g3", "p4")
		assert.NoError(t, err)
		assert.Equal(t, vo.StatusVoting, game.Status)
		repo.AssertExpectations(t)
		pub.AssertExpectations(t)
	})

	t.Run("Reconciles pending vote when only missing voter leaves", func(t *testing.T) {
		repo := new(GameRepoMock)
		pub := new(EventPublisherMock)
		svc := NewGameService(repo, nil, pub)

		game := entity.NewGame("g4", "123456", "p1", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
		p1 := entity.NewPlayer("p1", "P1", "a1")
		p2 := entity.NewPlayer("p2", "P2", "a2")
		p3 := entity.NewPlayer("p3", "P3", "a3")
		p4 := entity.NewPlayer("p4", "P4", "a4")
		_, _ = game.Join(p1)
		_, _ = game.Join(p2)
		_, _ = game.Join(p3)
		_, _ = game.Join(p4)
		game.Status = vo.StatusVoting
		p1.IsImpostor = true
		p1.HasVoted = true
		p1.VoteTargetID = "p2"
		p2.HasVoted = true
		p2.VoteTargetID = "p3"
		p3.HasVoted = true
		p3.VoteTargetID = "p2"

		repo.On("GetByID", mock.Anything, vo.GameID("g4")).Return(game, nil).Once()
		repo.On("Save", mock.Anything, mock.AnythingOfType("*entity.Game")).Return(nil).Once()
		pub.On("PublishGameUpdate", mock.Anything, "g4").Return(nil).Once()
		pub.On("PublishPlayerEvent", mock.Anything, "g4", "LEFT", "p4", "P4", "a4").Return(nil).Once()

		err := svc.LeaveGame(context.Background(), "g4", "p4")
		assert.NoError(t, err)
		assert.Equal(t, vo.StatusResult, game.Status)
		assert.Equal(t, "impostors", game.WinnerTeam)
		assert.Equal(t, "p2", game.ExpelledID)
		repo.AssertExpectations(t)
		pub.AssertExpectations(t)
	})
}

func TestGameService_SubmitDecision(t *testing.T) {
	t.Run("Transitions to Voting when majority wants to vote", func(t *testing.T) {
		repo := new(GameRepoMock)
		pub := new(EventPublisherMock)
		svc := NewGameService(repo, nil, pub)

		game := entity.NewGame("g1", "123456", "h", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
		p1 := entity.NewPlayer("p1", "P1", "a1")
		p2 := entity.NewPlayer("p2", "P2", "a2")
		p3 := entity.NewPlayer("p3", "P3", "a3")
		_, _ = game.Join(p1)
		_, _ = game.Join(p2)
		_, _ = game.Join(p3)
		game.Status = vo.StatusDecision
		p1.HasDecided = true
		p1.WantsToVote = true
		p2.HasDecided = true
		p2.WantsToVote = false

		repo.On("GetByID", mock.Anything, vo.GameID("g1")).Return(game, nil).Once()
		repo.On("Save", mock.Anything, game).Return(nil).Once()
		pub.On("PublishGameUpdate", mock.Anything, "g1").Return(nil).Once()

		req := request.DecisionRequest{VoteToVoting: true}
		updatedGame, err := svc.SubmitDecision(context.Background(), "g1", "p3", req)
		assert.NoError(t, err)
		assert.Equal(t, vo.StatusVoting, updatedGame.Status)
	})

	t.Run("Transitions to Playing on tie", func(t *testing.T) {
		repo := new(GameRepoMock)
		pub := new(EventPublisherMock)
		svc := NewGameService(repo, nil, pub)

		game := entity.NewGame("g2", "123456", "h", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
		p1 := entity.NewPlayer("p1", "P1", "a1")
		p2 := entity.NewPlayer("p2", "P2", "a2")
		_, _ = game.Join(p1)
		_, _ = game.Join(p2)
		game.Status = vo.StatusDecision
		p1.HasDecided = true
		p1.WantsToVote = true

		repo.On("GetByID", mock.Anything, vo.GameID("g2")).Return(game, nil).Once()
		repo.On("Save", mock.Anything, game).Return(nil).Once()
		pub.On("PublishGameUpdate", mock.Anything, "g2").Return(nil).Once()

		req := request.DecisionRequest{VoteToVoting: false}
		updatedGame, err := svc.SubmitDecision(context.Background(), "g2", "p2", req)
		assert.NoError(t, err)
		assert.Equal(t, vo.StatusPlaying, updatedGame.Status)
	})
}

func TestGameService_UpdateSettingsAndRematch(t *testing.T) {
	repo := new(GameRepoMock)
	wordRepo := new(WordRepoMock)
	pub := new(EventPublisherMock)
	svc := NewGameService(repo, wordRepo, pub)

	t.Run("UpdateSettings", func(t *testing.T) {
		game := entity.NewGame("g1", "123456", "h", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
		_, _ = game.Join(entity.NewPlayer("h", "H", "a1"))

		repo.On("GetByID", mock.Anything, vo.GameID("g1")).Return(game, nil).Once()
		repo.On("Save", mock.Anything, game).Return(nil).Once()
		pub.On("PublishGameUpdate", mock.Anything, "g1").Return(nil).Once()

		req := request.UpdateSettingsRequest{
			Categories:    []string{"sports"},
			ImpostorCount: 2,
			JuniorMode:    true,
			SurvivalMode:  true,
			TimerEnabled:  true,
			TimerSeconds:  45,
		}
		updatedGame, err := svc.UpdateSettings(context.Background(), "g1", "h", req)
		assert.NoError(t, err)
		assert.Equal(t, 2, updatedGame.Settings.ImpostorCount)
		assert.True(t, updatedGame.Settings.JuniorMode)
		assert.Equal(t, vo.CategoryID("sports"), updatedGame.Settings.CategoryIDs[0])
		assert.Equal(t, 45, updatedGame.Settings.TimerSeconds)
	})

	t.Run("Rematch", func(t *testing.T) {
		game := entity.NewGame("g2", "123456", "h", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
		p1, p2 := entity.NewPlayer("p1", "P1", "a1"), entity.NewPlayer("p2", "P2", "a2")
		_, _ = game.Join(p1)
		_, _ = game.Join(p2)
		game.Status = vo.StatusFinished

		word := &entity.Word{Text: "Tiger", CategoryID: vo.CategoryAnimals}

		repo.On("GetByID", mock.Anything, vo.GameID("g2")).Return(game, nil).Once()
		wordRepo.On("GetRandomWord", mock.Anything, mock.Anything, false, vo.LanguageSpanish).Return(word, nil).Once()
		repo.On("Save", mock.Anything, game).Return(nil).Once()
		pub.On("PublishGameUpdate", mock.Anything, "g2").Return(nil).Once()

		reqGame, err := svc.Rematch(context.Background(), "g2")
		assert.NoError(t, err)
		assert.Equal(t, vo.StatusAdPhase, reqGame.Status)
		assert.Equal(t, "Tiger", reqGame.Word)
	})
}
