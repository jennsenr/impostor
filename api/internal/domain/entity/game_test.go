package entity

import (
	"testing"

	"github.com/jennsenr/impostor/api/internal/domain/errs"
	"github.com/jennsenr/impostor/api/internal/domain/vo"
	"github.com/stretchr/testify/assert"
)

func TestGame_Join(t *testing.T) {
	settings := vo.NewSettings([]vo.CategoryID{vo.CategoryAnimals}, 1, vo.LanguageSpanish, false, false, false, true, 60)

	t.Run("Successfully join", func(t *testing.T) {
		game := NewGame("game-1", "1234", "host-1", settings)
		p := NewPlayer("p2", "Player 2", "avatar-2")
		_, err := game.Join(p)
		assert.NoError(t, err)
		assert.Len(t, game.Players, 1)
	})

	t.Run("Successfully rejoin", func(t *testing.T) {
		game := NewGame("game-1", "1234", "host-1", settings)
		p1 := NewPlayer("p1", "Player 1", "avatar-1")
		_, _ = game.Join(p1)
		p1.IsConnected = false

		p1_again := NewPlayer("p1-new-id", "Player 1", "avatar-1")
		isRejoin, err := game.Join(p1_again)
		assert.NoError(t, err)
		assert.True(t, isRejoin)
		assert.Equal(t, "p1-new-id", game.Players[0].ID)
	})

	t.Run("Fail when avatar already taken", func(t *testing.T) {
		game := NewGame("game-1", "1234", "host-1", settings)
		_, _ = game.Join(NewPlayer("p1", "Player 1", "avatar-1"))

		p2 := NewPlayer("p2", "Player 2", "avatar-1")
		_, err := game.Join(p2)
		assert.ErrorIs(t, err, errs.ErrAvatarAlreadyTaken)
	})

	t.Run("Fail when game full", func(t *testing.T) {
		gameFull := NewGame("gf", "1234", "h", settings)
		for i := 0; i < 15; i++ {
			pID := vo.NewGameID().String()
			_, _ = gameFull.Join(NewPlayer(pID, "P"+pID, vo.AvatarID("a"+pID)))
		}
		p := NewPlayer("p-full", "Full", "avatar-full")
		_, err := gameFull.Join(p)
		assert.ErrorIs(t, err, errs.ErrGameFull)
	})

	t.Run("Fail when game already started", func(t *testing.T) {
		game := NewGame("g", "123", "h", settings)
		game.Status = vo.StatusPlaying
		p := NewPlayer("p-late", "Late", "a-late")
		_, err := game.Join(p)
		assert.ErrorIs(t, err, errs.ErrGameAlreadyStarted)
	})
}

func TestGame_Start_RoleAssignment(t *testing.T) {
	settings := vo.NewSettings([]vo.CategoryID{"animals"}, 1, vo.LanguageSpanish, false, false, false, true, 60)
	game := NewGame("game-1", "1234", "host-1", settings)

	h := NewPlayer("host-1", "Host", "avatar-1")
	h.AdCompleted = true
	p2 := NewPlayer("p2", "Player 2", "avatar-2")
	p2.AdCompleted = true
	p3 := NewPlayer("p3", "Player 3", "avatar-3")
	p3.AdCompleted = true

	_, _ = game.Join(h)
	_, _ = game.Join(p2)
	_, _ = game.Join(p3)

	t.Run("Fail if not host", func(t *testing.T) {
		err := game.Start("not-host", &Word{Text: "X"})
		assert.ErrorIs(t, err, errs.ErrNotHost)
	})

	t.Run("Fail if not enough players", func(t *testing.T) {
		smallGame := NewGame("g2", "123456", "h", settings)
		hp := NewPlayer("h", "H", "a")
		hp.AdCompleted = true
		_, _ = smallGame.Join(hp)
		err := smallGame.Start("h", &Word{Text: "X"})
		assert.ErrorIs(t, err, errs.ErrMinimumPlayersRequired)
	})

	t.Run("Assigns roles correctly", func(t *testing.T) {
		err := game.Start("host-1", &Word{Text: "Apple"})
		assert.NoError(t, err)
		assert.Equal(t, vo.StatusAdPhase, game.Status)

		impostors := 0
		for _, p := range game.Players {
			if p.IsImpostor {
				impostors++
			}
		}
		assert.Equal(t, 1, impostors)
	})

	t.Run("Assigns the configured number of impostors", func(t *testing.T) {
		configuredSettings := vo.NewSettings([]vo.CategoryID{"animals"}, 2, vo.LanguageSpanish, false, false, false, true, 60)
		configuredGame := NewGame("game-2", "4321", "host-1", configuredSettings)
		players := []*Player{
			NewPlayer("host-1", "Host", "avatar-1"),
			NewPlayer("p2", "Player 2", "avatar-2"),
			NewPlayer("p3", "Player 3", "avatar-3"),
			NewPlayer("p4", "Player 4", "avatar-4"),
		}

		for _, player := range players {
			player.AdCompleted = true
			_, _ = configuredGame.Join(player)
		}

		err := configuredGame.Start("host-1", &Word{Text: "Apple"})
		assert.NoError(t, err)

		impostors := 0
		for _, player := range configuredGame.Players {
			if player.IsImpostor {
				impostors++
			}
		}

		assert.Equal(t, 2, impostors)
	})
}

func TestGame_Leave_AdjustsImpostorCount(t *testing.T) {
	settings := vo.NewSettings([]vo.CategoryID{vo.CategoryAnimals}, 4, vo.LanguageSpanish, false, false, false, true, 60)
	game := NewGame("g1", "123456", "p1", settings)
	players := []*Player{
		NewPlayer("p1", "P1", "a1"),
		NewPlayer("p2", "P2", "a2"),
		NewPlayer("p3", "P3", "a3"),
		NewPlayer("p4", "P4", "a4"),
		NewPlayer("p5", "P5", "a5"),
	}

	for _, player := range players {
		_, _ = game.Join(player)
		player.IsAlive = true
	}

	game.Status = vo.StatusWaiting
	game.Players[0].IsImpostor = true
	game.Players[1].IsImpostor = true
	game.Players[2].IsImpostor = true
	game.Players[3].IsImpostor = true

	err := game.Leave("p5")
	assert.NoError(t, err)
	assert.Equal(t, 3, game.Settings.ImpostorCount)

	impostors := 0
	for _, player := range game.Players {
		if player.IsImpostor {
			impostors++
		}
	}

	assert.Equal(t, 3, impostors)
}

func TestGame_CalculateResults(t *testing.T) {
	t.Run("Impostors win when they equal civilians", func(t *testing.T) {
		game := NewGame("g1", "123456", "h", vo.NewSettings([]vo.CategoryID{vo.CategoryAnimals}, 1, vo.LanguageSpanish, false, false, false, true, 60))
		h, p2, p3 := NewPlayer("h", "H", "a1"), NewPlayer("p2", "P2", "a2"), NewPlayer("p3", "P3", "a3")
		_, _ = game.Join(h)
		_, _ = game.Join(p2)
		_, _ = game.Join(p3)
		h.IsAlive, p2.IsAlive, p3.IsAlive = true, true, true

		h.IsImpostor = true
		game.Status = vo.StatusVoting
		_ = game.Vote("h", "p2")
		_ = game.Vote("p2", "h")
		_ = game.Vote("p3", "p2") // p2 expulsado

		_, _, gameOver, winner := game.CalculateResults()
		assert.True(t, gameOver)
		assert.Equal(t, "impostors", winner)
	})

	t.Run("No one expelled on tie", func(t *testing.T) {
		// En modo supervivencia, un empate no termina la partida
		settings := vo.Settings{CategoryIDs: []vo.CategoryID{vo.CategoryAnimals}, ImpostorCount: 1, SurvivalMode: true, TimerEnabled: true, TimerSeconds: 60}
		game := NewGame("g1", "123456", "h", settings)
		h, p2, p3 := NewPlayer("h", "H", "a1"), NewPlayer("p2", "P2", "a2"), NewPlayer("p3", "P3", "a3")
		_, _ = game.Join(h)
		_, _ = game.Join(p2)
		_, _ = game.Join(p3)
		h.IsAlive, p2.IsAlive, p3.IsAlive = true, true, true
		h.IsImpostor = true // Necesario para que no ganen los civiles por goleada

		game.Status = vo.StatusVoting
		_ = game.Vote("h", "p2")
		_ = game.Vote("p2", "p3")
		_ = game.Vote("p3", "h") // Triple empate

		expelled, _, gameOver, _ := game.CalculateResults()
		assert.Empty(t, expelled)
		assert.False(t, gameOver)
		assert.Equal(t, vo.StatusResult, game.Status)
	})

	t.Run("Classic mode still enters result before final screen", func(t *testing.T) {
		settings := vo.Settings{CategoryIDs: []vo.CategoryID{vo.CategoryAnimals}, ImpostorCount: 1, SurvivalMode: false, TimerEnabled: true, TimerSeconds: 60}
		game := NewGame("g1", "123456", "h", settings)
		h, p2, p3 := NewPlayer("h", "H", "a1"), NewPlayer("p2", "P2", "a2"), NewPlayer("p3", "P3", "a3")
		_, _ = game.Join(h)
		_, _ = game.Join(p2)
		_, _ = game.Join(p3)
		h.IsAlive, p2.IsAlive, p3.IsAlive = true, true, true
		p3.IsImpostor = true

		game.Status = vo.StatusVoting
		_ = game.Vote("h", "p3")
		_ = game.Vote("p2", "p3")
		_ = game.Vote("p3", "h")

		expelled, wasImpostor, gameOver, winner := game.CalculateResults()
		assert.Equal(t, "p3", expelled)
		assert.True(t, wasImpostor)
		assert.True(t, gameOver)
		assert.Equal(t, "civilians", winner)
		assert.Equal(t, vo.StatusResult, game.Status)
		assert.Equal(t, "civilians", game.WinnerTeam)
	})
}

func TestGame_FinishPlayerAd(t *testing.T) {
	game := NewGame("g1", "123456", "h", vo.NewSettings([]vo.CategoryID{vo.CategoryAnimals}, 1, vo.LanguageSpanish, false, false, false, true, 60))
	h := NewPlayer("h", "H", "a1")
	p2 := NewPlayer("p2", "P2", "a2")
	_, _ = game.Join(h)
	_, _ = game.Join(p2)

	t.Run("Finish ad correctly", func(t *testing.T) {
		err := game.FinishPlayerAd("p2")
		assert.NoError(t, err)
		assert.True(t, p2.AdCompleted)
	})
}

func TestGame_TurnAssignment(t *testing.T) {
	settings := vo.NewSettings([]vo.CategoryID{vo.CategoryAnimals}, 1, vo.LanguageSpanish, false, false, false, true, 60)

	t.Run("Skips dead starter", func(t *testing.T) {
		game := NewGame("g1", "12345", "h", settings)
		p1, p2, p3 := NewPlayer("p1", "P1", "a1"), NewPlayer("p2", "P2", "a2"), NewPlayer("p3", "P3", "a3")
		_, _ = game.Join(p1)
		_, _ = game.Join(p2)
		_, _ = game.Join(p3)
		game.StarterIndex = 0

		game.Players[0].IsAlive = false // Starter is dead
		game.Players[1].IsAlive = true
		game.Players[2].IsAlive = true

		game.Status = vo.StatusDecision
		err := game.SetStatus(vo.StatusPlaying)
		assert.NoError(t, err)

		// CurrentTurnIndex should skip 0 and go to 1
		assert.Equal(t, 1, game.CurrentTurnIndex)
	})

	t.Run("NextTurn skips dead players", func(t *testing.T) {
		game := NewGame("g1", "12345", "h", settings)
		p1, p2, p3 := NewPlayer("p1", "P1", "a1"), NewPlayer("p2", "P2", "a2"), NewPlayer("p3", "P3", "a3")
		_, _ = game.Join(p1)
		_, _ = game.Join(p2)
		_, _ = game.Join(p3)
		game.StarterIndex = 0
		game.CurrentTurnIndex = 0

		game.Players[0].IsAlive = true
		game.Players[1].IsAlive = false // Next is dead
		game.Players[2].IsAlive = true

		game.Status = vo.StatusPlaying
		err := game.NextTurn()
		assert.NoError(t, err)

		// It was 0, it should skip 1 and go to 2
		assert.Equal(t, 2, game.CurrentTurnIndex)
	})
}

func TestGame_QuestionsMode(t *testing.T) {
	t.Run("Ready shuffles order and starts from index zero", func(t *testing.T) {
		settings := vo.NewSettings([]vo.CategoryID{vo.CategoryAnimals}, 1, vo.LanguageSpanish, false, false, true, true, 60)
		game := NewGame("g1", "12345", "h", settings)
		p1, p2, p3 := NewPlayer("p1", "P1", "a1"), NewPlayer("p2", "P2", "a2"), NewPlayer("p3", "P3", "a3")
		_, _ = game.Join(p1)
		_, _ = game.Join(p2)
		_, _ = game.Join(p3)
		game.Status = vo.StatusReady

		_ = game.Ready("p1")
		_ = game.Ready("p2")
		err := game.Ready("p3")

		assert.NoError(t, err)
		assert.Equal(t, vo.StatusPlaying, game.Status)
		assert.Equal(t, 0, game.StarterIndex)
		assert.Equal(t, 0, game.CurrentTurnIndex)
		for i, player := range game.Players {
			assert.Equal(t, i, player.OrderIndex)
		}
	})

	t.Run("Next round from result reshuffles alive players first", func(t *testing.T) {
		settings := vo.NewSettings([]vo.CategoryID{vo.CategoryAnimals}, 1, vo.LanguageSpanish, false, false, true, true, 60)
		game := NewGame("g1", "12345", "h", settings)
		p1, p2, p3, p4 := NewPlayer("p1", "P1", "a1"), NewPlayer("p2", "P2", "a2"), NewPlayer("p3", "P3", "a3"), NewPlayer("p4", "P4", "a4")
		_, _ = game.Join(p1)
		_, _ = game.Join(p2)
		_, _ = game.Join(p3)
		_, _ = game.Join(p4)
		game.Status = vo.StatusResult
		p3.IsAlive = false

		err := game.SetStatus(vo.StatusPlaying)

		assert.NoError(t, err)
		assert.Equal(t, vo.StatusPlaying, game.Status)
		assert.Equal(t, 0, game.StarterIndex)
		assert.Equal(t, 0, game.CurrentTurnIndex)
		assert.True(t, game.Players[0].IsAlive)
		assert.True(t, game.Players[1].IsAlive)
		assert.True(t, game.Players[2].IsAlive)
		assert.False(t, game.Players[3].IsAlive)
	})
}

func TestGame_Leave_PreservesActiveRolesDuringStartedGame(t *testing.T) {
	settings := vo.NewSettings([]vo.CategoryID{vo.CategoryAnimals}, 1, vo.LanguageSpanish, false, false, false, true, 60)
	game := NewGame("g1", "12345", "h", settings)
	host := NewPlayer("h", "Host", "a1")
	civilian := NewPlayer("p2", "P2", "a2")
	impostor := NewPlayer("p3", "P3", "a3")

	_, _ = game.Join(host)
	_, _ = game.Join(civilian)
	_, _ = game.Join(impostor)

	game.Status = vo.StatusPlaying
	impostor.IsImpostor = true

	err := game.Leave("p2")

	assert.NoError(t, err)
	assert.Len(t, game.Players, 2)
	assert.True(t, impostor.IsImpostor)
	assert.Equal(t, 1, game.Settings.ImpostorCount)
}

func TestGame_Rematch(t *testing.T) {
	t.Run("Rotates StarterIndex and resets state", func(t *testing.T) {
		settings := vo.NewSettings([]vo.CategoryID{vo.CategoryAnimals}, 1, vo.LanguageSpanish, false, false, false, true, 60)
		game := NewGame("g1", "123456", "h", settings)
		p1, p2 := NewPlayer("p1", "P1", "a1"), NewPlayer("p2", "P2", "a2")
		_, _ = game.Join(p1)
		_, _ = game.Join(p2)

		game.StarterIndex = 0
		game.Status = vo.StatusFinished
		p1.IsAlive = false
		p1.VoteTargetID = "p2"

		err := game.Rematch("NewWord", "", vo.CategoryAnimals)
		assert.NoError(t, err)

		// Should rotate starter to 1
		assert.Equal(t, 1, game.StarterIndex)
		assert.Equal(t, 1, game.CurrentTurnIndex)

		// State should reset
		assert.Equal(t, vo.StatusAdPhase, game.Status)
		assert.True(t, p1.IsAlive)
		assert.Empty(t, p1.VoteTargetID)
	})

	t.Run("Chooses a different impostor when possible", func(t *testing.T) {
		settings := vo.NewSettings([]vo.CategoryID{vo.CategoryAnimals}, 1, vo.LanguageSpanish, false, false, false, true, 60)
		game := NewGame("g1", "123456", "h", settings)
		p1, p2, p3 := NewPlayer("p1", "P1", "a1"), NewPlayer("p2", "P2", "a2"), NewPlayer("p3", "P3", "a3")
		_, _ = game.Join(p1)
		_, _ = game.Join(p2)
		_, _ = game.Join(p3)

		game.Status = vo.StatusFinished
		p2.IsImpostor = true

		err := game.Rematch("NewWord", "", vo.CategoryAnimals)
		assert.NoError(t, err)

		impostorCount := 0
		for _, p := range game.Players {
			if p.IsImpostor {
				impostorCount++
			}
		}

		assert.Equal(t, 1, impostorCount)
	})

	t.Run("Does not pin impostor to the same player across many rematches", func(t *testing.T) {
		settings := vo.NewSettings([]vo.CategoryID{vo.CategoryAnimals}, 1, vo.LanguageSpanish, false, false, false, true, 60)
		game := NewGame("g1", "123456", "h", settings)
		players := []*Player{
			NewPlayer("p1", "P1", "a1"),
			NewPlayer("p2", "P2", "a2"),
			NewPlayer("p3", "P3", "a3"),
			NewPlayer("p4", "P4", "a4"),
		}

		for _, p := range players {
			_, _ = game.Join(p)
		}

		game.Status = vo.StatusFinished

		selected := map[string]int{}
		for i := 0; i < 64; i++ {
			err := game.Rematch("NewWord", "", vo.CategoryAnimals)
			assert.NoError(t, err)

			currentImpostorCount := 0
			for _, p := range game.Players {
				if p.IsImpostor {
					selected[p.ID]++
					currentImpostorCount++
				}
			}

			assert.Equal(t, 1, currentImpostorCount)
			game.Status = vo.StatusFinished
		}

		assert.Greater(t, len(selected), 1)
	})
}
