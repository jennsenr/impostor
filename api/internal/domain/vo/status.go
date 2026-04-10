package vo

type Status string

const (
	StatusWaiting    Status = "WAITING"
	StatusAdPhase    Status = "AD_PHASE"
	StatusReady      Status = "READY"
	StatusPlaying    Status = "PLAYING"
	StatusDecision   Status = "DECISION"
	StatusVoting     Status = "VOTING"
	StatusResult     Status = "RESULT"
	StatusFinished   Status = "FINISHED"
)
