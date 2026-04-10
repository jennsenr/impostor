package entity

import (
	cryptorand "crypto/rand"
	"math/big"

	"github.com/jennsenr/impostor/api/internal/domain/errs"
	"github.com/jennsenr/impostor/api/internal/domain/vo"
)

type Game struct {
	ID               vo.GameID     `json:"id"`
	Code             string        `json:"code"`
	Status           vo.Status     `json:"status"`
	Players          []*Player     `json:"players"`
	Settings         vo.Settings   `json:"settings"`
	CurrentRound     int           `json:"current_round"`
	CurrentTurnIndex int           `json:"current_turn_index"`
	Word                     string        `json:"word"`
	WordImageURL             string        `json:"word_image_url,omitempty"`
	ActiveCategoryID         vo.CategoryID `json:"active_category_id,omitempty"`
	ActiveCategoryName       string        `json:"active_category_name,omitempty"`
	HostID                   string        `json:"host_id"`
	HostIsPremium            bool          `json:"host_is_premium"`

	// Partida
	WinnerTeam   string `json:"winner_team,omitempty"`
	ExpelledID   string `json:"expelled_id,omitempty"`
	StarterIndex int    `json:"starter_index"`
}

func NewGame(id vo.GameID, code string, hostID string, settings vo.Settings) *Game {
	return &Game{
		ID:            id,
		Code:          code,
		Status:        vo.StatusWaiting,
		Players:       []*Player{},
		Settings:      settings,
		CurrentRound:  1,
		HostID:        hostID,
		HostIsPremium: false,
		StarterIndex:  0,
	}
}

// Join añade un jugador al juego o permite re-unirse si ya existe por ID o nombre.
// Devuelve un booleano indicando si el jugador ya estaba en la partida (re-unión).
func (g *Game) Join(p *Player) (bool, error) {
	// 1. Buscar coincidencia por ID (Prioridad máxima para re-unión exacta)
	for _, existing := range g.Players {
		if existing.ID == p.ID {
			// Re-unión por ID: Actualizar datos y permitir
			existing.Name = p.Name
			existing.AvatarID = p.AvatarID
			existing.IsConnected = true
			return true, nil
		}
	}

	// 2. Buscar coincidencia por NOMBRE (Para re-uniones tras pérdida de ID/Caché)
	for _, existing := range g.Players {
		if existing.Name == p.Name {
			// Si el original sigue CONECTADO, rechazamos el duplicado
			if existing.IsConnected {
				return false, errs.ErrNameAlreadyTaken
			}
			// Si está DESCONECTADO, permitimos reclamar el hueco
			oldID := existing.ID
			existing.ID = p.ID
			existing.AvatarID = p.AvatarID
			existing.IsConnected = true

			// Actualizar HostID si el que se fue era el host
			if g.HostID == oldID {
				g.HostID = p.ID
			}
			return true, nil
		}
	}

	// 3. Jugador NUEVO: Validar disponibilidad de Avatar
	for _, existing := range g.Players {
		if existing.AvatarID == p.AvatarID {
			// Solo bloqueamos si el dueño del avatar está conectado
			// o si la partida ya empezó.
			if existing.IsConnected || g.Status != vo.StatusWaiting {
				return false, errs.ErrAvatarAlreadyTaken
			}
		}
	}

	// 4. Validar estado y capacidad para nuevos jugadores
	if g.Status != vo.StatusWaiting {
		return false, errs.ErrGameAlreadyStarted
	}
	if len(g.Players) >= 15 {
		return false, errs.ErrGameFull
	}

	g.Players = append(g.Players, p)
	return false, nil
}

// Leave elimina a un jugador de la partida. Si el host se va, se asigna uno nuevo.
func (g *Game) Leave(playerID string) error {
	index := -1
	for i, p := range g.Players {
		if p.ID == playerID {
			index = i
			break
		}
	}

	if index == -1 {
		return errs.ErrPlayerNotFound
	}

	// Eliminar jugador
	g.Players = append(g.Players[:index], g.Players[index+1:]...)

	// Reajustar índices de turno si el jugador eliminado estaba antes que el actual
	if index < g.CurrentTurnIndex {
		g.CurrentTurnIndex--
	} else if index == g.CurrentTurnIndex {
		// Si era el turno del que se fue, el siguiente jugador hereda el turno
		if len(g.Players) > 0 {
			g.CurrentTurnIndex = g.CurrentTurnIndex % len(g.Players)
		} else {
			g.CurrentTurnIndex = 0
		}
	}

	// Reajustar el índice de inicio de ronda
	if index < g.StarterIndex {
		g.StarterIndex--
	}
	if len(g.Players) > 0 {
		g.StarterIndex = g.StarterIndex % len(g.Players)
		if g.StarterIndex < 0 {
			g.StarterIndex = 0
		}
	} else {
		g.StarterIndex = 0
	}

	// Si el jugador que se fue era el host, asignar uno nuevo
	if g.HostID == playerID && len(g.Players) > 0 {
		g.HostID = g.Players[0].ID
	}

	return nil
}

// UpdateSettings permite al host cambiar la configuración de la sala.
func (g *Game) UpdateSettings(hostID string, settings vo.Settings) error {
	if g.HostID != hostID {
		return errs.ErrNotHost
	}
	if g.Status != vo.StatusWaiting {
		return errs.ErrInvalidStatus
	}
	g.Settings = settings
	return nil
}

// SetPlayerConnectivity actualiza el estado de conexión de un jugador.
func (g *Game) SetPlayerConnectivity(playerID string, connected bool) bool {
	for _, p := range g.Players {
		if p.ID == playerID {
			if p.IsConnected != connected {
				p.IsConnected = connected
				return true // Hubo cambio
			}
			return false
		}
	}
	return false
}

// Start inicia el juego si hay suficientes jugadores y todos han completado el anuncio.
// Realiza la asignación de roles y selecciona la palabra de una categoría aleatoria.
func (g *Game) Start(hostID string, word *Word) error {
	if g.HostID != hostID {
		return errs.ErrNotHost
	}

	// Validar mínimo de jugadores (3 en prod, 2 en debug)
	// Como el backend no sabe si es debug, usamos 2 para facilitar pruebas del usuario
	if len(g.Players) < 2 {
		return errs.ErrMinimumPlayersRequired
	}

	if g.Status != vo.StatusWaiting {
		return errs.ErrInvalidStatus
	}

	// Posponer la lógica de categorías hasta el Service para que el Service pase la palabra correcta.
	// El entity.Start ahora solo recibe el objeto Word ya seleccionado por el Service.

	// Asignar palabra y categoría activa
	g.Word = word.Text
	g.WordImageURL = word.ImageURL
	g.ActiveCategoryID = word.CategoryID

	for _, c := range vo.GetAvailableCategories() {
		if c.ID == word.CategoryID {
			g.ActiveCategoryName = c.Name
			break
		}
	}
	if g.ActiveCategoryName == "" {
		g.ActiveCategoryName = string(word.CategoryID)
	}

	// Asignar roles (Impostores)
	// Por defecto: 1 impostor (pronto será personalizable)
	numImpostors := 1

	impostorIndices := make(map[int]bool)
	for len(impostorIndices) < numImpostors && len(g.Players) > 0 {
		idx, err := randomInt(len(g.Players))
		if err != nil {
			return err
		}
		impostorIndices[idx] = true
	}

	// Seleccionar StarterIndex aleatorio para que el host no empiece siempre
	if len(g.Players) > 0 {
		idx, err := randomInt(len(g.Players))
		if err != nil {
			return err
		}
		g.StarterIndex = idx
	}

	for i := 0; i < len(g.Players); i++ {
		g.Players[i].IsImpostor = impostorIndices[i]
		g.Players[i].OrderIndex = i
		g.Players[i].IsAlive = true
		g.Players[i].IsReady = false
		g.Players[i].AdCompleted = false
	}

	g.Status = vo.StatusAdPhase
	return nil
}

// FinishPlayerAd marca el anuncio como completado para un jugador específico.
// Si todos han completado el anuncio, la partida pasa a READY.
func (g *Game) FinishPlayerAd(playerID string) error {
	found := false
	for _, p := range g.Players {
		if p.ID == playerID {
			p.AdCompleted = true
			found = true
			break
		}
	}
	if !found {
		return errs.ErrPlayerNotFound
	}

	// Si todos terminaron anuncios, pasar a READY
	allDone := true
	for _, p := range g.Players {
		if !p.AdCompleted {
			allDone = false
			break
		}
	}
	if allDone {
		g.Status = vo.StatusReady
	}
	return nil
}

// AdFinished transiciona de AD_PHASE a READY (fase antigua por compatibilidad)
func (g *Game) AdFinished() error {
	if g.Status != vo.StatusAdPhase {
		return errs.ErrInvalidStatus
	}
	g.Status = vo.StatusReady
	return nil
}

// Ready marca a un jugador como listo tras ver su rol.
// Si todos están listos, la partida pasa a PLAYING.
func (g *Game) Ready(playerID string) error {
	if g.Status != vo.StatusReady {
		return errs.ErrInvalidStatus
	}

	found := false
	allReady := true
	for _, p := range g.Players {
		if p.ID == playerID {
			p.IsReady = true
			found = true
		}
		if !p.IsReady {
			allReady = false
		}
	}

	if !found {
		return errs.ErrPlayerNotFound
	}

	if allReady {
		g.Status = vo.StatusPlaying
		g.CurrentRound = 1
		g.CurrentTurnIndex = g.StarterIndex
	}

	return nil
}

// NextTurn avanza al siguiente jugador vivo.
// Si termina la ronda, pasa a DECISION.
func (g *Game) NextTurn() error {
	if g.Status != vo.StatusPlaying {
		return errs.ErrInvalidStatus
	}

	// Buscar el siguiente jugador vivo
	for i := 0; i < len(g.Players); i++ {
		g.CurrentTurnIndex = (g.CurrentTurnIndex + 1) % len(g.Players)
		// Si hemos vuelto al jugador que empezó, la ronda ha terminado
		if g.CurrentTurnIndex == g.StarterIndex {
			g.Status = vo.StatusDecision
			for _, p := range g.Players {
				p.HasDecided = false
				p.WantsToVote = false
			}
			return nil
		}

		if g.Players[g.CurrentTurnIndex].IsAlive {
			return nil
		}
	}

	return nil
}

// GetCurrentTurnPlayerID devuelve el ID del jugador que tiene el turno actual.
func (g *Game) GetCurrentTurnPlayerID() string {
	if g.CurrentTurnIndex < 0 || g.CurrentTurnIndex >= len(g.Players) {
		return ""
	}
	return g.Players[g.CurrentTurnIndex].ID
}

// SetStatus permite cambiar el estado (ej. de DECISION a VOTING o a PLAYING para la siguiente ronda)
func (g *Game) SetStatus(status vo.Status) error {
	// Guardar el estado anterior para lógica de reset
	oldStatus := g.Status
	g.Status = status

	// Lógica de transición según el estado al que ENTRAMOS
	switch status {
	case vo.StatusPlaying:
		if oldStatus == vo.StatusDecision || oldStatus == vo.StatusResult {
			g.CurrentRound++
			g.CurrentTurnIndex = g.StarterIndex

			// Asegurar que el primer turno se asigne a un jugador vivo
			if len(g.Players) > 0 {
				for i := 0; i < len(g.Players); i++ {
					if g.Players[g.CurrentTurnIndex].IsAlive {
						break
					}
					g.CurrentTurnIndex = (g.CurrentTurnIndex + 1) % len(g.Players)
				}
			}
		}
		// REINICIAR FLAGS para la nueva ronda de juego
		for _, p := range g.Players {
			p.HasVoted = false
			p.VoteTargetID = ""
			p.HasDecided = false
			p.WantsToVote = false
		}

	case vo.StatusVoting:
		// Limpiar votos previos por seguridad
		for _, p := range g.Players {
			p.HasVoted = false
			p.VoteTargetID = ""
			p.HasDecided = false
			p.WantsToVote = false
		}

	case vo.StatusDecision:
		// Limpiar decisiones al entrar (aunque ya se hace en NextTurn, reforzamos)
		for _, p := range g.Players {
			p.HasDecided = false
			p.WantsToVote = false
		}
	}
	return nil
}

// Vote registra un voto de un jugador hacia otro.
func (g *Game) Vote(voterID, targetID string) error {
	if g.Status != vo.StatusVoting {
		return errs.ErrInvalidStatus
	}

	var voter *Player
	var target *Player
	for _, p := range g.Players {
		if p.ID == voterID {
			voter = p
		}
		if p.ID == targetID {
			target = p
		}
	}

	if voter == nil || target == nil || !voter.IsAlive || !target.IsAlive || voterID == targetID {
		return errs.ErrInvalidStatus
	}

	voter.HasVoted = true
	voter.VoteTargetID = targetID

	// Si todos han votado, se podría disparar el cálculo, pero se hará vía Service por seguridad
	return nil
}

// CalculateResults procesa quién es expulsado y si la partida termina.
// Devuelve: expulsadoID, fueImpostor, partidaTerminada, equipoGanador
func (g *Game) CalculateResults() (string, bool, bool, string) {
	if g.Status != vo.StatusVoting {
		// Si ya se calcularon resultados, los devolvemos de forma idempotente
		if g.Status == vo.StatusFinished || g.Status == vo.StatusResult {
			wasImpostor := false
			for _, p := range g.Players {
				if p.ID == g.ExpelledID {
					wasImpostor = p.IsImpostor
					break
				}
			}
			return g.ExpelledID, wasImpostor, g.Status == vo.StatusFinished, g.WinnerTeam
		}
		return "", false, false, ""
	}

	// Contar votos
	votesCount := make(map[string]int)
	maxVotes := 0
	for _, p := range g.Players {
		if p.IsAlive && p.HasVoted && p.VoteTargetID != "" {
			votesCount[p.VoteTargetID]++
			if votesCount[p.VoteTargetID] > maxVotes {
				maxVotes = votesCount[p.VoteTargetID]
			}
		}
	}

	// Identificar candidatos con máximo de votos (para detectar empates)
	var candidates []string
	for id, count := range votesCount {
		if count == maxVotes && maxVotes > 0 {
			candidates = append(candidates, id)
		}
	}

	expelledID := ""
	wasImpostor := false

	// Regla: Empate -> Nadie es expulsado
	if len(candidates) == 1 {
		expelledID = candidates[0]
		g.ExpelledID = expelledID
		for _, p := range g.Players {
			if p.ID == expelledID {
				p.IsAlive = false // ¡Expulsado!
				wasImpostor = p.IsImpostor
				break
			}
		}
	} else {
		g.ExpelledID = "" // Limpiar si hubo empate y nadie salio
	}

	// Comprobar victorias
	gameOver := false
	winnerTeam := ""

	// Contar supervivientes
	impostorsAlive := 0
	civiliansAlive := 0
	for _, p := range g.Players {
		if p.IsAlive {
			if p.IsImpostor {
				impostorsAlive++
			} else {
				civiliansAlive++
			}
		}
	}

	if g.Settings.SurvivalMode {
		// Modo Supervivencia: La partida continua hasta que se elimine al impostor
		// o hasta que los impostores igualen/superen a los civiles (ej: quedan 2 jugadores, 1 impostor y 1 civil).
		if impostorsAlive == 0 {
			gameOver = true
			winnerTeam = "civilians"
		} else if civiliansAlive <= impostorsAlive {
			gameOver = true
			winnerTeam = "impostors"
		}
	} else {
		// Modo Clásico (No Supervivencia): Solo hay UNA oportunidad de votación.
		// Si en esta votación no matan al impostor, el impostor gana automáticamente.
		gameOver = true
		if impostorsAlive == 0 {
			winnerTeam = "civilians"
		} else {
			winnerTeam = "impostors"
		}
	}

	if gameOver {
		g.Status = vo.StatusFinished
		g.WinnerTeam = winnerTeam // Guardar en el struct
	} else {
		g.Status = vo.StatusResult
	}

	return expelledID, wasImpostor, gameOver, winnerTeam
}

// Rematch reinicia el estado de la partida para una nueva vuelta
func (g *Game) Rematch(word string, wordImageUrl string, categoryID vo.CategoryID) error {
	if g.Status != vo.StatusFinished {
		return errs.ErrInvalidStatus
	}

	previousImpostorIndex := -1
	for i, p := range g.Players {
		if p.IsImpostor {
			previousImpostorIndex = i
			break
		}
	}

	// Resetear jugadores
	for _, p := range g.Players {
		p.IsReady = false
		p.AdCompleted = false
		p.IsAlive = true
		p.IsImpostor = false
		p.HasVoted = false
		p.HasDecided = false
		p.VoteTargetID = ""
	}

	// Incrementar StarterIndex para rotar al siguiente jugador en la partida repetida
	if len(g.Players) > 0 {
		g.StarterIndex = (g.StarterIndex + 1) % len(g.Players)
	}

	g.CurrentTurnIndex = g.StarterIndex
	g.CurrentRound = 1
	g.Word = word
	g.WordImageURL = wordImageUrl
	g.ActiveCategoryID = categoryID

	for _, c := range vo.GetAvailableCategories() {
		if c.ID == categoryID {
			g.ActiveCategoryName = c.Name
			break
		}
	}
	if g.ActiveCategoryName == "" {
		g.ActiveCategoryName = string(categoryID)
	}

	g.WinnerTeam = ""
	g.ExpelledID = ""
	g.Status = vo.StatusAdPhase

	// Reseteo de jugadores
	for _, p := range g.Players {
		p.IsAlive = true
		p.HasVoted = false
		p.HasDecided = false
		p.WantsToVote = false
		p.VoteTargetID = ""
		p.IsImpostor = false
		p.IsReady = false
		p.AdCompleted = false // Resetear para la nueva partida
	}

	// Sortear nuevo impostor
	if len(g.Players) > 0 {
		imposterIndex := previousImpostorIndex
		if len(g.Players) == 1 {
			imposterIndex = 0
		} else {
			for imposterIndex == previousImpostorIndex {
				nextIndex, err := randomInt(len(g.Players))
				if err != nil {
					return err
				}
				imposterIndex = nextIndex
			}
		}
		g.Players[imposterIndex].IsImpostor = true
	}

	return nil
}

// ShouldHideWordForPlayer indica si la palabra debe seguir oculta para este jugador.
// El impostor no debe verla durante la partida, pero sí cuando ya ha terminado.
func (g *Game) ShouldHideWordForPlayer(playerID string) bool {
	if g.Status == vo.StatusFinished {
		return false
	}
	for _, p := range g.Players {
		if p.ID == playerID {
			return p.IsImpostor
		}
	}

	return true // Por seguridad, ocultar si el jugador no existe
}

// SanitizeForPlayer devuelve una copia de la partida con los datos sensibles ocultos para el jugador dado.
// IMPORTANTE: Devuelve una copia para evitar mutar el estado compartido en caché/memoria.
func (g *Game) SanitizeForPlayer(playerID string) *Game {
	// Realizar una copia superficial de la estructura.
	// Aunque Players es un slice de punteros, no lo estamos modificando aquí,
	// así que es seguro para serialización JSON.
	clone := *g

	if g.ShouldHideWordForPlayer(playerID) {
		clone.Word = ""
		clone.WordImageURL = ""
	}

	return &clone
}



func randomInt(max int) (int, error) {
	if max <= 0 {
		return 0, errs.ErrInternal
	}

	n, err := cryptorand.Int(cryptorand.Reader, big.NewInt(int64(max)))
	if err != nil {
		return 0, errs.ErrInternal
	}

	return int(n.Int64()), nil
}
