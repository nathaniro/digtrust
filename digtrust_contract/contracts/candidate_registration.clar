;; Advanced Voting Smart Contract with Extended Features
;; Comprehensive voting system with registration, validation, delegation, and governance

;; Contract owner/admin
(define-constant CONTRACT_OWNER tx-sender)

;; Error constants
(define-constant ERR_NOT_AUTHORIZED (err u1001))
(define-constant ERR_CANDIDATE_EXISTS (err u1002))
(define-constant ERR_CANDIDATE_NOT_FOUND (err u1003))
(define-constant ERR_ALREADY_VOTED (err u1004))
(define-constant ERR_INVALID_CANDIDATE_ID (err u1005))
(define-constant ERR_EMPTY_NAME (err u1006))
(define-constant ERR_VOTING_INACTIVE (err u1007))
(define-constant ERR_VOTING_ENDED (err u1008))
(define-constant ERR_NOT_REGISTERED (err u1009))
(define-constant ERR_ALREADY_REGISTERED (err u1010))
(define-constant ERR_INSUFFICIENT_STAKE (err u1011))
(define-constant ERR_DELEGATION_FAILED (err u1012))
(define-constant ERR_INVALID_TIME (err u1013))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u1014))
(define-constant ERR_PROPOSAL_EXPIRED (err u1015))
(define-constant ERR_INVALID_PERCENTAGE (err u1016))

;; Constants
(define-constant MINIMUM_STAKE u1000000) ;; 1 STX minimum stake
(define-constant VOTING_PERIOD_BLOCKS u1440) ;; ~1 day in blocks (10 min per block)
(define-constant QUORUM_PERCENTAGE u30) ;; 30% quorum required

;; Data variables
(define-data-var next-candidate-id uint u1)
(define-data-var next-proposal-id uint u1)
(define-data-var voting-active bool true)
(define-data-var voting-start-block uint u0)
(define-data-var voting-end-block uint u0)
(define-data-var total-registered-voters uint u0)
(define-data-var total-votes-cast uint u0)
(define-data-var registration-required bool false)
(define-data-var delegation-enabled bool true)
(define-data-var weighted-voting bool false)

;; Data maps
;; Store candidate information
(define-map candidates 
    { candidate-id: uint }
    { 
        name: (string-ascii 100),
        description: (string-ascii 500),
        vote-count: uint,
        weighted-vote-count: uint,
        active: bool,
        registration-block: uint
    }
)

;; Voter registration and information
(define-map registered-voters
    principal
    {
        registered: bool,
        stake-amount: uint,
        registration-block: uint,
        voting-weight: uint
    }
)

;; Track if a voter has already voted
(define-map voter-has-voted principal bool)

;; Track which candidate each voter voted for
(define-map voter-choice principal uint)

;; Vote delegation system
(define-map vote-delegation
    principal ;; delegator
    {
        delegate: principal,
        active: bool,
        delegation-block: uint
    }
)

;; Track delegates and their delegated vote count
(define-map delegate-info
    principal
    {
        delegated-votes: uint,
        delegated-weight: uint
    }
)

;; Governance proposals
(define-map proposals
    { proposal-id: uint }
    {
        title: (string-ascii 100),
        description: (string-ascii 1000),
        proposer: principal,
        votes-for: uint,
        votes-against: uint,
        start-block: uint,
        end-block: uint,
        executed: bool,
        proposal-type: (string-ascii 50)
    }
)

;; Proposal votes
(define-map proposal-votes
    { proposal-id: uint, voter: principal }
    {
        vote: bool, ;; true = for, false = against
        weight: uint,
        block-height: uint
    }
)

;; Vote history for audit trail
(define-map vote-history
    { voter: principal, election-round: uint }
    {
        candidate-id: uint,
        timestamp: uint,
        block-height: uint,
        vote-weight: uint
    }
)

;; Private functions

;; Check if caller is contract owner/admin
(define-private (is-owner)
    (is-eq tx-sender CONTRACT_OWNER)
)

;; Validate candidate name is not empty
(define-private (is-valid-name (name (string-ascii 100)))
    (> (len name) u0)
)

;; Check if voter is registered (when registration is required)
(define-private (is-voter-registered (voter principal))
    (if (var-get registration-required)
        (default-to false (get registered (map-get? registered-voters voter)))
        true
    )
)

;; Get voter's voting weight
(define-private (get-voting-weight (voter principal))
    (if (var-get weighted-voting)
        (default-to u1 (get voting-weight (map-get? registered-voters voter)))
        u1
    )
)

;; Check if voting period is active
(define-private (is-voting-period-active)
    (let 
        (
            (current-block block-height)
            (start-block (var-get voting-start-block))
            (end-block (var-get voting-end-block))
        )
        (and 
            (>= current-block start-block)
            (<= current-block end-block)
        )
    )
)

;; Calculate quorum based on total registered voters
(define-private (calculate-quorum)
    (/ (* (var-get total-registered-voters) QUORUM_PERCENTAGE) u100)
)

;; Public functions

;; Register to vote (with optional staking)
(define-public (register-voter (stake-amount uint))
    (let 
        (
            (voter tx-sender)
            (current-block block-height)
        )
        ;; Check if already registered
        (asserts! (is-none (map-get? registered-voters voter)) ERR_ALREADY_REGISTERED)
        
        ;; Check minimum stake if weighted voting is enabled
        (if (var-get weighted-voting)
            (asserts! (>= stake-amount MINIMUM_STAKE) ERR_INSUFFICIENT_STAKE)
            true
        )
        
        ;; Calculate voting weight based on stake
        (let 
            (
                (voting-weight (if (var-get weighted-voting) 
                                   (/ stake-amount MINIMUM_STAKE)
                                   u1))
            )
            ;; Register voter
            (map-set registered-voters voter
                {
                    registered: true,
                    stake-amount: stake-amount,
                    registration-block: current-block,
                    voting-weight: voting-weight
                }
            )
            
            ;; Increment total registered voters
            (var-set total-registered-voters (+ (var-get total-registered-voters) u1))
            
            ;; Transfer stake if required (simplified - in real implementation would use STX transfer)
            (ok voting-weight)
        )
    )
)

;; Add a new candidate with description
(define-public (add-candidate (name (string-ascii 100)) (description (string-ascii 500)))
    (let 
        (
            (candidate-id (var-get next-candidate-id))
        )
        ;; Check if caller is authorized
        (asserts! (is-owner) ERR_NOT_AUTHORIZED)
        
        ;; Validate candidate name
        (asserts! (is-valid-name name) ERR_EMPTY_NAME)
        
        ;; Add candidate to map
        (map-set candidates 
            { candidate-id: candidate-id }
            { 
                name: name,
                description: description,
                vote-count: u0,
                weighted-vote-count: u0,
                active: true,
                registration-block: block-height
            }
        )
        
        ;; Increment next candidate ID
        (var-set next-candidate-id (+ candidate-id u1))
        
        (ok candidate-id)
    )
)

;; Delegate vote to another address
(define-public (delegate-vote (delegate principal))
    (let 
        (
            (delegator tx-sender)
        )
        (asserts! (var-get delegation-enabled) ERR_NOT_AUTHORIZED)
        (asserts! (is-voter-registered delegator) ERR_NOT_REGISTERED)
        (asserts! (is-voter-registered delegate) ERR_NOT_REGISTERED)
        (asserts! (not (has-voted delegator)) ERR_ALREADY_VOTED)
        
        ;; Set delegation
        (map-set vote-delegation delegator
            {
                delegate: delegate,
                active: true,
                delegation-block: block-height
            }
        )
        
        ;; Update delegate info
        (let 
            (
                (current-delegate-info (default-to 
                    { delegated-votes: u0, delegated-weight: u0 }
                    (map-get? delegate-info delegate)))
                (delegator-weight (get-voting-weight delegator))
            )
            (map-set delegate-info delegate
                {
                    delegated-votes: (+ (get delegated-votes current-delegate-info) u1),
                    delegated-weight: (+ (get delegated-weight current-delegate-info) delegator-weight)
                }
            )
        )
        
        (ok true)
    )
)

;; Vote for a candidate (enhanced with delegation support)
(define-public (vote (candidate-id uint))
    (let 
        (
            (candidate-info (map-get? candidates { candidate-id: candidate-id }))
            (voter tx-sender)
            (current-block block-height)
        )
        ;; Check if voting is active and within time period
        (asserts! (var-get voting-active) ERR_VOTING_INACTIVE)
        (asserts! (is-voting-period-active) ERR_VOTING_ENDED)
        
        ;; Check voter registration
        (asserts! (is-voter-registered voter) ERR_NOT_REGISTERED)
        
        ;; Check if candidate exists and is active
        (asserts! (is-some candidate-info) ERR_CANDIDATE_NOT_FOUND)
        
        ;; Check if voter has already voted
        (asserts! (not (has-voted voter)) ERR_ALREADY_VOTED)
        
        ;; Get candidate info and voting weight
        (match candidate-info
            candidate-data 
            (let 
                (
                    (vote-weight (+ (get-voting-weight voter) 
                                    (default-to u0 (get delegated-weight (map-get? delegate-info voter)))))
                )
                (asserts! (get active candidate-data) ERR_CANDIDATE_NOT_FOUND)
                
                ;; Record that voter has voted
                (map-set voter-has-voted voter true)
                
                ;; Record voter's choice
                (map-set voter-choice voter candidate-id)
                
                ;; Update vote counts
                (map-set candidates 
                    { candidate-id: candidate-id }
                    (merge candidate-data { 
                        vote-count: (+ (get vote-count candidate-data) u1),
                        weighted-vote-count: (+ (get weighted-vote-count candidate-data) vote-weight)
                    })
                )
                
                ;; Record vote history
                (map-set vote-history
                    { voter: voter, election-round: u1 }
                    {
                        candidate-id: candidate-id,
                        timestamp: current-block,
                        block-height: current-block,
                        vote-weight: vote-weight
                    }
                )
                
                ;; Increment total votes cast
                (var-set total-votes-cast (+ (var-get total-votes-cast) u1))
                
                (ok vote-weight)
            )
            ERR_CANDIDATE_NOT_FOUND
        )
    )
)

;; Create governance proposal
(define-public (create-proposal (title (string-ascii 100)) (description (string-ascii 1000)) (proposal-type (string-ascii 50)))
    (let 
        (
            (proposal-id (var-get next-proposal-id))
            (proposer tx-sender)
            (start-block block-height)
            (end-block (+ block-height VOTING_PERIOD_BLOCKS))
        )
        (asserts! (is-voter-registered proposer) ERR_NOT_REGISTERED)
        
        ;; Create proposal
        (map-set proposals
            { proposal-id: proposal-id }
            {
                title: title,
                description: description,
                proposer: proposer,
                votes-for: u0,
                votes-against: u0,
                start-block: start-block,
                end-block: end-block,
                executed: false,
                proposal-type: proposal-type
            }
        )
        
        (var-set next-proposal-id (+ proposal-id u1))
        (ok proposal-id)
    )
)

;; Vote on governance proposal
(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
    (let 
        (
            (voter tx-sender)
            (proposal-info (map-get? proposals { proposal-id: proposal-id }))
            (vote-weight (get-voting-weight voter))
        )
        (asserts! (is-some proposal-info) ERR_PROPOSAL_NOT_FOUND)
        (asserts! (is-voter-registered voter) ERR_NOT_REGISTERED)
        
        (match proposal-info
            proposal-data
            (begin
                (asserts! (<= block-height (get end-block proposal-data)) ERR_PROPOSAL_EXPIRED)
                (asserts! (is-none (map-get? proposal-votes { proposal-id: proposal-id, voter: voter })) ERR_ALREADY_VOTED)
                
                ;; Record vote
                (map-set proposal-votes
                    { proposal-id: proposal-id, voter: voter }
                    {
                        vote: vote-for,
                        weight: vote-weight,
                        block-height: block-height
                    }
                )
                
                ;; Update proposal vote counts
                (if vote-for
                    (map-set proposals { proposal-id: proposal-id }
                        (merge proposal-data { votes-for: (+ (get votes-for proposal-data) vote-weight) }))
                    (map-set proposals { proposal-id: proposal-id }
                        (merge proposal-data { votes-against: (+ (get votes-against proposal-data) vote-weight) }))
                )
                
                (ok true)
            )
            ERR_PROPOSAL_NOT_FOUND
        )
    )
)

;; Set voting period
(define-public (set-voting-period (start-block uint) (end-block uint))
    (begin
        (asserts! (is-owner) ERR_NOT_AUTHORIZED)
        (asserts! (> end-block start-block) ERR_INVALID_TIME)
        
        (var-set voting-start-block start-block)
        (var-set voting-end-block end-block)
        (ok true)
    )
)

;; Toggle features
(define-public (toggle-registration-required)
    (begin
        (asserts! (is-owner) ERR_NOT_AUTHORIZED)
        (var-set registration-required (not (var-get registration-required)))
        (ok (var-get registration-required))
    )
)

(define-public (toggle-delegation)
    (begin
        (asserts! (is-owner) ERR_NOT_AUTHORIZED)
        (var-set delegation-enabled (not (var-get delegation-enabled)))
        (ok (var-get delegation-enabled))
    )
)

(define-public (toggle-weighted-voting)
    (begin
        (asserts! (is-owner) ERR_NOT_AUTHORIZED)
        (var-set weighted-voting (not (var-get weighted-voting)))
        (ok (var-get weighted-voting))
    )
)

;; Emergency functions
(define-public (emergency-stop)
    (begin
        (asserts! (is-owner) ERR_NOT_AUTHORIZED)
        (var-set voting-active false)
        (ok true)
    )
)

(define-public (reset-election)
    (begin
        (asserts! (is-owner) ERR_NOT_AUTHORIZED)
        (var-set total-votes-cast u0)
        (var-set voting-active true)
        (ok true)
    )
)

;; Read-only functions

;; Get candidate information with enhanced details
(define-read-only (get-candidate-full (candidate-id uint))
    (map-get? candidates { candidate-id: candidate-id })
)

;; Get voter registration info
(define-read-only (get-voter-info (voter principal))
    (map-get? registered-voters voter)
)

;; Check if voter has voted
(define-read-only (has-voted (voter principal))
    (default-to false (map-get? voter-has-voted voter))
)

;; Get vote delegation info
(define-read-only (get-delegation-info (voter principal))
    (map-get? vote-delegation voter)
)

;; Get delegate's delegated vote info
(define-read-only (get-delegate-info (delegate principal))
    (map-get? delegate-info delegate)
)

;; Get proposal information
(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals { proposal-id: proposal-id })
)

;; Get voting statistics
(define-read-only (get-voting-stats)
    {
        total-registered: (var-get total-registered-voters),
        total-votes-cast: (var-get total-votes-cast),
        voting-active: (var-get voting-active),
        quorum-required: (calculate-quorum),
        current-block: block-height,
        voting-start: (var-get voting-start-block),
        voting-end: (var-get voting-end-block)
    }
)

;; Get election results summary
(define-read-only (get-election-summary)
    {
        total-candidates: (- (var-get next-candidate-id) u1),
        total-voters: (var-get total-registered-voters),
        votes-cast: (var-get total-votes-cast),
        turnout-percentage: (if (> (var-get total-registered-voters) u0)
                                (/ (* (var-get total-votes-cast) u100) (var-get total-registered-voters))
                                u0),
        registration-required: (var-get registration-required),
        delegation-enabled: (var-get delegation-enabled),
        weighted-voting: (var-get weighted-voting)
    }
)

;; Check if quorum is met
(define-read-only (is-quorum-met)
    (>= (var-get total-votes-cast) (calculate-quorum))
)

;; Get vote history
(define-read-only (get-vote-history (voter principal) (election-round uint))
    (map-get? vote-history { voter: voter, election-round: election-round })
)

;; Get contract configuration
(define-read-only (get-contract-config)
    {
        owner: CONTRACT_OWNER,
        minimum-stake: MINIMUM_STAKE,
        voting-period-blocks: VOTING_PERIOD_BLOCKS,
        quorum-percentage: QUORUM_PERCENTAGE,
        next-candidate-id: (var-get next-candidate-id),
        next-proposal-id: (var-get next-proposal-id)
    }
)