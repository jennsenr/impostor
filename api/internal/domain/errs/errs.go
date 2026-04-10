package errs

import "errors"

var (
	// ErrGameNotFound se devuelve cuando no se encuentra una partida por su ID.
	ErrGameNotFound = errors.New("game_not_found")

	// ErrPlayerAlreadyExists se devuelve cuando un jugador intenta unirse con un nombre o avatar ya en uso.
	ErrPlayerAlreadyExists = errors.New("player_already_exists")

	// ErrNameAlreadyTaken se devuelve cuando el nombre de usuario ya está siendo usado por otro jugador CONECTADO.
	ErrNameAlreadyTaken = errors.New("name_already_taken")

	// ErrAvatarAlreadyTaken se devuelve cuando el avatar seleccionado ya está ocupado.
	ErrAvatarAlreadyTaken = errors.New("avatar_already_taken")

	// ErrGameAlreadyStarted se devuelve cuando alguien intenta unirse a una partida que ya no está en WAITING.
	ErrGameAlreadyStarted = errors.New("game_already_started")

	// ErrGameFull se devuelve cuando la partida ha alcanzado su límite de jugadores.
	ErrGameFull = errors.New("game_full")

	// ErrInvalidStatus se devuelve cuando se intenta realizar una acción no permitida en el estado actual.
	ErrInvalidStatus = errors.New("invalid_game_status")

	// ErrNotHost se devuelve cuando un jugador intenta realizar una acción reservada al host.
	ErrNotHost = errors.New("not_host")

	// ErrMinimumPlayersRequired se devuelve cuando se intenta iniciar una partida con menos de 3 jugadores.
	ErrMinimumPlayersRequired = errors.New("minimum_players_required")

	// ErrPlayerNotFound se devuelve cuando no se encuentra al jugador en la partida.
	ErrPlayerNotFound = errors.New("player_not_found")

	// ErrInvalidCategory se devuelve cuando la categoría no es válida para el modo seleccionado.
	ErrInvalidCategory = errors.New("invalid_category")

	// ErrInternal se devuelve para errores técnicos que deben ser logueados en infraestructura.
	ErrInternal = errors.New("internal_server_error")
)
