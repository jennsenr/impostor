package test

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
	"github.com/jennsenr/impostor/api/internal/infrastructure/handler"
	"github.com/jennsenr/impostor/api/internal/infrastructure/router"
	"github.com/stretchr/testify/assert"
)

func performRequest(r *gin.Engine, method, path string, body any, headers map[string]string) *httptest.ResponseRecorder {
	var b []byte
	if body != nil {
		b, _ = json.Marshal(body)
	}
	w := httptest.NewRecorder()
	req, _ := http.NewRequest(method, path, bytes.NewBuffer(b))
	for k, v := range headers {
		req.Header.Set(k, v)
	}
	r.ServeHTTP(w, req)
	return w
}

func TestFullGame_E2E(t *testing.T) {
	gin.SetMode(gin.TestMode)

	// Setup
	gameRepo := NewInMemoryGameRepository()
	wordRepo := NewInMemoryWordRepository()
	publisher := &InMemoryEventPublisher{}
	gameService := service.NewGameService(gameRepo, wordRepo, publisher)
	gameHandler := handler.NewGameHandler(gameService)
	// wsHandler mock if needed, but not used for REST E2E
	r := router.NewRouter(gameHandler, nil)

	var gameID string
	var hostID string
	var p2ID string
	var p3ID string

	// 1. Host creates game
	t.Run("1. Create Game", func(t *testing.T) {
		createReq := request.CreateGameRequest{
			HostName:   "Alice (Host)",
			AvatarID:   "avatar-1",
			Categories: []string{"animals"},
		}
		w := performRequest(r, "POST", "/v1/games", createReq, nil)
		assert.Equal(t, http.StatusCreated, w.Code)

		var resp entity.Game
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		gameID = string(resp.ID)
		hostID = resp.HostID
		assert.NotEmpty(t, gameID)
		assert.Equal(t, "Alice (Host)", resp.Players[0].Name)
	})

	// 2. Player 2 joins
	t.Run("2. Player 2 Joins", func(t *testing.T) {
		joinReq := request.JoinGameRequest{PlayerName: "Bob", AvatarID: "avatar-2"}
		path := "/v1/games/" + gameID + "/join"
		w := performRequest(r, "POST", path, joinReq, nil)
		assert.Equal(t, http.StatusOK, w.Code)

		var resp map[string]any
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		p2ID = resp["player_id"].(string)
		assert.NotEmpty(t, p2ID)
	})

	// 3. Player 3 joins
	t.Run("3. Player 3 Joins", func(t *testing.T) {
		joinReq := request.JoinGameRequest{PlayerName: "Charlie", AvatarID: "avatar-3"}
		path := "/v1/games/" + gameID + "/join"
		w := performRequest(r, "POST", path, joinReq, nil)
		assert.Equal(t, http.StatusOK, w.Code)

		var resp map[string]any
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		p3ID = resp["player_id"].(string)
	})

	// 4. Host starts game
	t.Run("4. Start Game", func(t *testing.T) {
		path := "/v1/games/" + gameID + "/start"
		headers := map[string]string{"X-Host-ID": hostID}
		w := performRequest(r, "POST", path, nil, headers)
		assert.Equal(t, http.StatusOK, w.Code)

		var resp entity.Game
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, vo.StatusAdPhase, resp.Status)
	})

	// 5. Finish Ad
	t.Run("5. Finish Ad", func(t *testing.T) {
		path := "/v1/games/" + gameID + "/ad-finished"
		w := performRequest(r, "POST", path, nil, map[string]string{"X-Player-ID": hostID})
		assert.Equal(t, http.StatusOK, w.Code)

		var resp entity.Game
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, vo.StatusAdPhase, resp.Status)

		w = performRequest(r, "POST", path, nil, map[string]string{"X-Player-ID": p2ID})
		assert.Equal(t, http.StatusOK, w.Code)
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, vo.StatusAdPhase, resp.Status)

		w = performRequest(r, "POST", path, nil, map[string]string{"X-Player-ID": p3ID})
		assert.Equal(t, http.StatusOK, w.Code)
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, vo.StatusReady, resp.Status)
	})

	// 6. All players mark as Ready
	t.Run("6. Players Ready", func(t *testing.T) {
		path := "/v1/games/" + gameID + "/ready"

		// Alice Ready
		performRequest(r, "POST", path, nil, map[string]string{"X-Player-ID": hostID})
		// Bob Ready
		performRequest(r, "POST", path, nil, map[string]string{"X-Player-ID": p2ID})
		// Charlie Ready
		w := performRequest(r, "POST", path, nil, map[string]string{"X-Player-ID": p3ID})

		assert.Equal(t, http.StatusOK, w.Code)
		var resp entity.Game
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, vo.StatusPlaying, resp.Status)
	})

	// 7. Play 3 turns (one per player)
	t.Run("7. Turns and transition to Voting", func(t *testing.T) {
		path := "/v1/games/" + gameID + "/next-turn"
		var w *httptest.ResponseRecorder
		for i := 0; i < 3; i++ {
			game, _ := gameRepo.GetByID(context.Background(), vo.GameID(gameID))
			currentPlayerID := game.GetCurrentTurnPlayerID()
			w = performRequest(
				r,
				"POST",
				path,
				nil,
				map[string]string{"X-Player-ID": currentPlayerID},
			)
		}

		var resp entity.Game
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, vo.StatusDecision, resp.Status)

		// Move to Voting (All players must decide)
		decisionPath := "/v1/games/" + gameID + "/decision"
		performRequest(r, "POST", decisionPath, request.DecisionRequest{VoteToVoting: true}, map[string]string{"X-Player-ID": hostID})
		performRequest(r, "POST", decisionPath, request.DecisionRequest{VoteToVoting: true}, map[string]string{"X-Player-ID": p2ID})
		w = performRequest(r, "POST", decisionPath, request.DecisionRequest{VoteToVoting: true}, map[string]string{"X-Player-ID": p3ID})

		assert.Equal(t, http.StatusOK, w.Code)
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, vo.StatusVoting, resp.Status)
	})

	// 8. Voting and check results
	t.Run("8. Vote and Calculate Results", func(t *testing.T) {
		// Identify impostor
		game, _ := gameRepo.GetByID(context.Background(), vo.GameID(gameID))
		var impostorID string
		var civilianIDs []string
		for _, p := range game.Players {
			if p.IsImpostor {
				impostorID = p.ID
			} else {
				civilianIDs = append(civilianIDs, p.ID)
			}
		}

		votePath := "/v1/games/" + gameID + "/vote"
		// Civilians vote for the impostor
		for _, cid := range civilianIDs {
			performRequest(r, "POST", votePath, request.VoteRequest{TargetID: impostorID}, map[string]string{"X-Player-ID": cid})
		}
		// Impostor votes for a civilian
		performRequest(r, "POST", votePath, request.VoteRequest{TargetID: civilianIDs[0]}, map[string]string{"X-Player-ID": impostorID})

		// Calculate Results
		resultsPath := "/v1/games/" + gameID + "/results"
		w := performRequest(r, "GET", resultsPath, nil, nil)
		assert.Equal(t, http.StatusOK, w.Code)

		var results map[string]any
		_ = json.Unmarshal(w.Body.Bytes(), &results)
		assert.Equal(t, impostorID, results["expelled_player_id"])
		assert.True(t, results["was_impostor"].(bool))
		assert.True(t, results["game_over"].(bool))
		assert.Equal(t, "civilians", results["winner_team"])
	})
}
