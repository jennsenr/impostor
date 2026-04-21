package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/jennsenr/impostor/api/internal/application/request"
	"github.com/jennsenr/impostor/api/internal/application/service"
	"github.com/jennsenr/impostor/api/internal/domain/entity"
	"github.com/jennsenr/impostor/api/internal/domain/vo"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

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

func (m *WordRepoMock) GetRandomWord(ctx context.Context, cat vo.CategoryID, junior bool, language vo.Language) (*entity.Word, error) {
	args := m.Called(ctx, cat, junior, language)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entity.Word), args.Error(1)
}

func (m *WordRepoMock) GetCategories(ctx context.Context, language vo.Language) ([]vo.Category, error) {
	args := m.Called(ctx, language)
	return args.Get(0).([]vo.Category), args.Error(1)
}

type PublisherMock struct{ mock.Mock }

func (m *PublisherMock) PublishGameUpdate(ctx context.Context, id string) error {
	return m.Called(ctx, id).Error(0)
}

func (m *PublisherMock) PublishPlayerEvent(ctx context.Context, gameID string, eventType string, playerID string, name string, avatarID string) error {
	return m.Called(ctx, gameID, eventType, playerID, name, avatarID).Error(0)
}

func TestGameHandler_CreateGame(t *testing.T) {
	gin.SetMode(gin.TestMode)
	repo := new(GameRepoMock)
	svc := service.NewGameService(repo, nil, nil)
	h := NewGameHandler(svc)
	r := gin.Default()
	r.POST("/api/games", h.CreateGame)

	t.Run("Success", func(t *testing.T) {
		reqBody := request.CreateGameRequest{HostName: "H", AvatarID: "a1", Categories: []string{"animals"}, ImpostorCount: 1}
		body, _ := json.Marshal(reqBody)
		repo.On("Save", mock.Anything, mock.AnythingOfType("*entity.Game")).Return(nil)
		w := httptest.NewRecorder()
		req, _ := http.NewRequest("POST", "/api/games", bytes.NewBuffer(body))
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusCreated, w.Code)
	})
}

func TestGameHandler_JoinGame(t *testing.T) {
	gin.SetMode(gin.TestMode)
	repo := new(GameRepoMock)
	pub := new(PublisherMock)
	svc := service.NewGameService(repo, nil, pub)
	h := NewGameHandler(svc)
	r := gin.Default()
	r.POST("/api/games/:id/join", h.JoinGame)

	t.Run("Success", func(t *testing.T) {
		game := entity.NewGame("g1", "1234", "h", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
		repo.On("GetByID", mock.Anything, vo.GameID("g1")).Return(game, nil)
		repo.On("Save", mock.Anything, game).Return(nil)
		pub.On("PublishGameUpdate", mock.Anything, "g1").Return(nil)
		pub.On("PublishPlayerEvent", mock.Anything, "g1", mock.Anything, mock.Anything, "P2", "a2").Return(nil)

		reqBody := request.JoinGameRequest{PlayerName: "P2", AvatarID: "a2"}
		body, _ := json.Marshal(reqBody)
		w := httptest.NewRecorder()
		req, _ := http.NewRequest("POST", "/api/games/g1/join", bytes.NewBuffer(body))
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusOK, w.Code)
	})
}

func TestGameHandler_GetGame_Redaction(t *testing.T) {
	t.Run("Redacts word for impostor", func(t *testing.T) {
		gin.SetMode(gin.TestMode)
		repo := new(GameRepoMock)
		svc := service.NewGameService(repo, nil, nil)
		h := NewGameHandler(svc)
		r := gin.Default()
		r.GET("/api/games/:id", h.GetGame)

		game := entity.NewGame("g1", "1234", "h", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
		game.Word = "Lion"
		p1 := entity.NewPlayer("p1", "P1", "a1")
		p1.IsImpostor = true
		_, _ = game.Join(p1) // Join while WAITING
		game.Status = vo.StatusPlaying

		repo.On("GetByID", mock.Anything, vo.GameID("g1")).Return(game, nil)

		w := httptest.NewRecorder()
		req, _ := http.NewRequest("GET", "/api/games/g1", nil)
		req.Header.Set("X-Player-ID", "p1")
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.NotContains(t, w.Body.String(), "Lion")
	})

	t.Run("Shows word for civilians", func(t *testing.T) {
		gin.SetMode(gin.TestMode)
		repo := new(GameRepoMock)
		svc := service.NewGameService(repo, nil, nil)
		h := NewGameHandler(svc)
		r := gin.Default()
		r.GET("/api/games/:id", h.GetGame)

		game := entity.NewGame("g1", "1234", "h", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
		game.Word = "Lion"
		p1 := entity.NewPlayer("p1", "P1", "a1")
		p1.IsImpostor = false // Civil
		_, _ = game.Join(p1)
		game.Status = vo.StatusPlaying

		repo.On("GetByID", mock.Anything, vo.GameID("g1")).Return(game, nil)

		w := httptest.NewRecorder()
		req, _ := http.NewRequest("GET", "/api/games/g1", nil)
		req.Header.Set("X-Player-ID", "p1")
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.Contains(t, w.Body.String(), "Lion")
	})

	t.Run("Shows word for impostor when game is finished", func(t *testing.T) {
		gin.SetMode(gin.TestMode)
		repo := new(GameRepoMock)
		svc := service.NewGameService(repo, nil, nil)
		h := NewGameHandler(svc)
		r := gin.Default()
		r.GET("/api/games/:id", h.GetGame)

		game := entity.NewGame("g1", "1234", "h", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
		game.Word = "Lion"
		p1 := entity.NewPlayer("p1", "P1", "a1")
		p1.IsImpostor = true
		_, _ = game.Join(p1)
		game.Status = vo.StatusFinished

		repo.On("GetByID", mock.Anything, vo.GameID("g1")).Return(game, nil)

		w := httptest.NewRecorder()
		req, _ := http.NewRequest("GET", "/api/games/g1", nil)
		req.Header.Set("X-Player-ID", "p1")
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.Contains(t, w.Body.String(), "Lion")
	})
}

func TestGameHandler_ActionAuthorization(t *testing.T) {
	t.Run("FinishAd requires player header", func(t *testing.T) {
		gin.SetMode(gin.TestMode)
		h := NewGameHandler(nil)
		r := gin.Default()
		r.POST("/api/games/:id/ad-finished", h.FinishAd)

		w := httptest.NewRecorder()
		req, _ := http.NewRequest("POST", "/api/games/g1/ad-finished", nil)
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})

	t.Run("NextTurn requires player header", func(t *testing.T) {
		gin.SetMode(gin.TestMode)
		h := NewGameHandler(nil)
		r := gin.Default()
		r.POST("/api/games/:id/next-turn", h.NextTurn)

		w := httptest.NewRecorder()
		req, _ := http.NewRequest("POST", "/api/games/g1/next-turn", nil)
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})

	t.Run("SubmitVote requires player header", func(t *testing.T) {
		gin.SetMode(gin.TestMode)
		h := NewGameHandler(nil)
		r := gin.Default()
		r.POST("/api/games/:id/vote", h.SubmitVote)

		body, _ := json.Marshal(request.VoteRequest{TargetID: "p2"})
		w := httptest.NewRecorder()
		req, _ := http.NewRequest("POST", "/api/games/g1/vote", bytes.NewBuffer(body))
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})

	t.Run("SubmitDecision requires player header", func(t *testing.T) {
		gin.SetMode(gin.TestMode)
		h := NewGameHandler(nil)
		r := gin.Default()
		r.POST("/api/games/:id/decision", h.SubmitDecision)

		body, _ := json.Marshal(request.DecisionRequest{VoteToVoting: true})
		w := httptest.NewRecorder()
		req, _ := http.NewRequest("POST", "/api/games/g1/decision", bytes.NewBuffer(body))
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})

	t.Run("UpdateSettings requires host header", func(t *testing.T) {
		gin.SetMode(gin.TestMode)
		h := NewGameHandler(nil)
		r := gin.Default()
		r.PUT("/api/games/:id/settings", h.UpdateSettings)

		body, _ := json.Marshal(request.UpdateSettingsRequest{Categories: []string{"animals"}, ImpostorCount: 1})
		w := httptest.NewRecorder()
		req, _ := http.NewRequest("PUT", "/api/games/g1/settings", bytes.NewBuffer(body))
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})

	t.Run("NextTurn rejects non current player", func(t *testing.T) {
		gin.SetMode(gin.TestMode)
		repo := new(GameRepoMock)
		pub := new(PublisherMock)
		svc := service.NewGameService(repo, nil, pub)
		h := NewGameHandler(svc)
		r := gin.Default()
		r.POST("/api/games/:id/next-turn", h.NextTurn)

		game := entity.NewGame("g1", "1234", "h", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
		_, _ = game.Join(entity.NewPlayer("p1", "P1", "a1"))
		_, _ = game.Join(entity.NewPlayer("p2", "P2", "a2"))
		game.Status = vo.StatusPlaying
		game.CurrentTurnIndex = 0

		repo.On("GetByID", mock.Anything, vo.GameID("g1")).Return(game, nil).Once()

		w := httptest.NewRecorder()
		req, _ := http.NewRequest("POST", "/api/games/g1/next-turn", nil)
		req.Header.Set("X-Player-ID", "p2")
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run("NextRound rejects non host", func(t *testing.T) {
		gin.SetMode(gin.TestMode)
		repo := new(GameRepoMock)
		pub := new(PublisherMock)
		svc := service.NewGameService(repo, nil, pub)
		h := NewGameHandler(svc)
		r := gin.Default()
		r.POST("/api/games/:id/next-round", h.NextRound)

		game := entity.NewGame("g1", "1234", "host", vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60))
		_, _ = game.Join(entity.NewPlayer("host", "Host", "a1"))
		_, _ = game.Join(entity.NewPlayer("p2", "P2", "a2"))
		game.Status = vo.StatusResult

		repo.On("GetByID", mock.Anything, vo.GameID("g1")).Return(game, nil).Once()

		w := httptest.NewRecorder()
		req, _ := http.NewRequest("POST", "/api/games/g1/next-round", nil)
		req.Header.Set("X-Player-ID", "p2")
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}

func TestGameHandler_RedirectToApp(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewGameHandler(nil)
	r := gin.Default()
	r.GET("/join/:code", h.RedirectToApp)

	t.Run("Success", func(t *testing.T) {
		w := httptest.NewRecorder()
		req, _ := http.NewRequest("GET", "/join/ABCD", nil)
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusOK, w.Code)
		assert.Contains(t, w.Body.String(), "impostor://join?code=ABCD")
	})
}
