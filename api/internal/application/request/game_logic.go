package request

type VoteRequest struct {
	TargetID string `json:"target_id" binding:"required"`
}

type DecisionRequest struct {
	VoteToVoting bool `json:"vote_to_voting"` // true to vote, false to continue
}
