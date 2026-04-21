// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class ImpostorLocalizationsEs extends ImpostorLocalizations {
  ImpostorLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Impostor Game';

  @override
  String get privacyAndConsent => 'PRIVACIDAD Y CONSENTIMIENTO';

  @override
  String get restoringRoom => 'RECUPERANDO SALA...';

  @override
  String get restoringRoomSubtitle =>
      'Intentando restaurar tu partida anterior.';

  @override
  String get errorFetchCategories => 'No se pudieron cargar las categorías.';

  @override
  String get errorNameRequired => 'Introduce tu nombre antes de continuar.';

  @override
  String get errorCategoryRequired => 'Selecciona al menos una categoría.';

  @override
  String get errorNameTaken => 'Ese nombre ya está en uso en la sala.';

  @override
  String get errorAvatarTaken => 'Ese avatar ya está ocupado.';

  @override
  String get errorJoinGame => 'No se pudo encontrar la sala. Revisa el código.';

  @override
  String get errorCreateGame => 'No se pudo crear la partida.';

  @override
  String get errorMinimumPlayers =>
      'No hay suficientes jugadores para esa cantidad de impostores.';

  @override
  String get errorSessionRestore =>
      'No se pudo recuperar la sala anterior. Puedes volver a entrar manualmente.';

  @override
  String get errorGeneric => 'Ha ocurrido un error.';

  @override
  String get errorNotHost => 'Solo el host puede hacer esa acción.';

  @override
  String get errorInvalidGameStatus =>
      'Esa acción no está disponible ahora mismo.';

  @override
  String get homeTitle => 'CONFIGURAR\nPARTIDA';

  @override
  String get homeSubtitle => 'ESTABLECER PROTOCOLOS';

  @override
  String get homeCategories => 'CATEGORÍAS';

  @override
  String get edit => 'EDITAR';

  @override
  String get noCategoriesSelected => 'Ninguna seleccionada. Pulsa EDITAR.';

  @override
  String get juniorMode => 'MODO JUNIOR';

  @override
  String get juniorModeSubtitle =>
      'Simplifica los términos para cadetes jóvenes.';

  @override
  String get survivalMode => 'MODO SUPERVIVENCIA';

  @override
  String get survivalModeSubtitle =>
      'La partida continúa si el jugador expulsado no era el impostor';

  @override
  String get questionsMode => 'MODO PREGUNTAS';

  @override
  String get questionsModeSubtitle =>
      'Haz preguntas para descubrir al impostor';

  @override
  String get timer => 'TEMPORIZADOR';

  @override
  String get timerSubtitle => 'Tiempo límite antes de perder el turno';

  @override
  String get impostors => 'IMPOSTORES';

  @override
  String get impostorsSubtitle =>
      'Configura cuántos impostores tendrá la partida.';

  @override
  String get categoriesLoadFailed => 'No se han podido cargar las categorías';

  @override
  String get retry => 'REINTENTAR';

  @override
  String get createGame => 'CREAR PARTIDA';

  @override
  String get roomCode => 'CÓDIGO';

  @override
  String get join => 'UNIRSE';

  @override
  String get selectCategories => 'SELECCIONAR CATEGORÍAS';

  @override
  String get selectCategoriesSubtitle => 'Escoge los mundos para jugar.';

  @override
  String get all => 'TODAS';

  @override
  String get doneProtocols => 'LISTO PROTOCOLOS';

  @override
  String get nameLabel => 'NOMBRE DEL TRIPULANTE';

  @override
  String get nameHint => 'INTRODUCE NOMBRE...';

  @override
  String get available => 'DISPONIBLE';

  @override
  String get selected => 'SELECCIONADO';

  @override
  String get occupied => 'OCUPADO';

  @override
  String get selectAvatarTitle => 'SELECCIONAR\nAVATAR';

  @override
  String get selectAvatarSubtitle => 'SELECCIONA TU AVATAR DE TRIPULACIÓN';

  @override
  String get bindAvatar => 'VINCULAR AVATAR';

  @override
  String get updateAvatar => 'ACTUALIZAR AVATAR';

  @override
  String get lobbyInactiveRoom => 'SALA INACTIVA: EL SERVIDOR LA HA CERRADO';

  @override
  String get lobbyErrorStartGame => 'No se pudo iniciar la partida.';

  @override
  String get lobbyErrorUpdateSettings => 'No se pudieron guardar los ajustes.';

  @override
  String get lobbyErrorAd => 'No se pudo confirmar el anuncio.';

  @override
  String get lobbyErrorLeave => 'No se pudo salir de la sala.';

  @override
  String get lobbyErrorDeleted => 'La sala ya no existe.';

  @override
  String get lobbyErrorGeneric => 'Ha ocurrido un error en la sala.';

  @override
  String get lobbyWaitingRoomLine1 => 'SALA DE';

  @override
  String get lobbyWaitingRoomLine2 => 'ESPERA';

  @override
  String get room => 'SALA';

  @override
  String get lobbyCodeLabel => 'CODIGO:';

  @override
  String get lobbyModesLabel => 'M O D O S :';

  @override
  String get questionsModeBadge => 'PREGUNTAS';

  @override
  String get waitingParticipantsLine1 => 'ESPERANDO';

  @override
  String get waitingParticipantsLine2 => 'PARTICIPANTES';

  @override
  String get playersLabel => 'JUGADORES';

  @override
  String get connected => 'CONECTADO';

  @override
  String get disconnected => 'DESCONECTADO';

  @override
  String get host => 'ANFITRIÓN';

  @override
  String get hostOffline => 'ANFITRIÓN (OFF)';

  @override
  String get startGame => 'EMPEZAR PARTIDA';

  @override
  String minimumPlayersButton(int count) {
    return 'MINIMO $count JUGADORES';
  }

  @override
  String get waitingForHost => 'ESPERANDO AL ANFITRIÓN...';

  @override
  String get gameSettings => 'AJUSTES DE PARTIDA';

  @override
  String get categories => 'Categorías';

  @override
  String get impostorLobbyHint =>
      'Para iniciar la sala hacen falta al menos impostores + 1 jugadores.';

  @override
  String get save => 'GUARDAR';

  @override
  String get saveChanges => 'GUARDAR CAMBIOS';

  @override
  String get discussionTime => 'TIEMPO DE DISCUSIÓN';

  @override
  String get juniorModeTitle => 'Modo Junior';

  @override
  String get survivalModeTitle => 'Modo Supervivencia';

  @override
  String get questionsModeTitle => 'Modo Preguntas';

  @override
  String get timerTitle => 'Temporizador';

  @override
  String get juniorCategoriesHint => 'Categorías simplificadas para niños';

  @override
  String shareLobbyInvite(Object code, Object url) {
    return '¡Únete a mi partida de IMPOSTOR!\n\nCódigo: $code\nEnlace: $url';
  }

  @override
  String get gameInactiveRoom => 'SALA INACTIVA: EL SERVIDOR LA HA CERRADO';

  @override
  String get leaveGameTitle => 'ABANDONAR PARTIDA';

  @override
  String get leaveGameBody =>
      'El resto de jugadores verá que has abandonado la partida.';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get exit => 'SALIR';

  @override
  String get unknownGameStatus => 'Estado de juego desconocido';

  @override
  String get gameErrorReady => 'No se pudo marcar al jugador como listo';

  @override
  String get gameErrorNextTurn => 'No se pudo avanzar el turno';

  @override
  String get gameErrorVote => 'No se pudo enviar el voto';

  @override
  String get gameErrorDecision => 'No se pudo enviar la decisión';

  @override
  String get gameErrorAd => 'No se pudo confirmar el anuncio';

  @override
  String get gameErrorRematch => 'No se pudo iniciar la revancha';

  @override
  String get gameErrorNextRound => 'No se pudo avanzar a la siguiente ronda';

  @override
  String get gameErrorGeneric => 'Ha ocurrido un error en la partida';

  @override
  String playerLeft(Object name) {
    return '$name ha abandonado la partida.';
  }

  @override
  String playerDisconnected(Object name) {
    return '$name se ha desconectado.';
  }

  @override
  String playerReconnected(Object name) {
    return '$name ha vuelto a entrar.';
  }

  @override
  String playerJoinedLobby(Object name) {
    return '$name ha entrado.';
  }

  @override
  String get round => 'RONDA';

  @override
  String get turnOf => 'TURNO DE:';

  @override
  String get readyShort => 'LISTO';

  @override
  String get decisionTitle => '¿SABÉIS YA QUIÉN ES?';

  @override
  String get decisionSubtitle =>
      'Hablad y decidid si queréis ir a votación ahora o jugar otra ronda.';

  @override
  String get teamDecisions => 'DECISIONES DEL EQUIPO';

  @override
  String get teamDecisionsSubtitle =>
      'Los jugadores en color ya han escogido si ir a votación o jugar otra ronda.';

  @override
  String get decisions => 'DECISIONES';

  @override
  String get goToVote => 'IR A VOTACIÓN';

  @override
  String get anotherRound => 'OTRA RONDA';

  @override
  String get playersDeciding => 'Los jugadores están decidiendo...';

  @override
  String waitingForOthers(int done, int total) {
    return 'Esperando a los demás ($done/$total)...';
  }

  @override
  String get youAreOut => '¡ESTÁS FUERA!';

  @override
  String get waitFinalResult => 'Espera al resultado final.';

  @override
  String get votesRegistered => 'VOTOS REGISTRADOS';

  @override
  String get votesProgressEliminated =>
      'Sigue el avance de la votación aunque ya no participes.';

  @override
  String get votes => 'VOTOS';

  @override
  String get voteRegistered => 'VOTO REGISTRADO';

  @override
  String get waitingRest => 'Esperando al resto...';

  @override
  String get votesProgressWaiting =>
      'Los jugadores iluminados ya han emitido su voto.';

  @override
  String get voteTheImpostor => 'VOTA AL IMPOSTOR';

  @override
  String get voteWarning => 'Si te equivocas, ¡lo pagarás caro!';

  @override
  String get votesProgressSubtitle =>
      'Los avatares en gris todavía no han votado.';

  @override
  String questionAsks(Object name) {
    return '$name PREGUNTA A';
  }

  @override
  String get questionLabel => 'PREGUNTA';

  @override
  String get answerLabel => 'RESPONDE';

  @override
  String get currentTurnResolutionFailed =>
      'No se pudo resolver el turno actual';

  @override
  String shareRoomCodeMessage(Object code) {
    return 'Únete a mi sala de Impostor. Código: $code';
  }

  @override
  String roomJoinChannelLabel(Object code) {
    return 'CANAL DE VINCULACIÓN: $code';
  }
}
