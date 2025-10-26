;; Multi-Send Cross-Chain Smart Contract
;; Enables batch token transfers with cross-chain bridge support

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INSUFFICIENT_BALANCE (err u101))
(define-constant ERR_INVALID_RECIPIENT (err u102))
(define-constant ERR_INVALID_AMOUNT (err u103))
(define-constant ERR_BRIDGE_NOT_SUPPORTED (err u104))
(define-constant ERR_ORACLE_FAILURE (err u105))
(define-constant ERR_CROSS_CHAIN_LOCKED (err u106))

;; Data Variables
(define-data-var contract-paused bool false)
(define-data-var bridge-fee-percentage uint u250) ;; 2.5% in basis points (250/10000)

;; Data Maps
(define-map authorized-bridges principal bool)
(define-map bridge-oracles principal principal) ;; bridge -> oracle mapping
(define-map cross-chain-locks 
    { sender: principal, nonce: uint } 
    { amount: uint, recipient: (string-ascii 64), target-chain: (string-ascii 32), timestamp: uint }
)
(define-map chain-supported (string-ascii 32) bool)

;; Read-only functions
(define-read-only (get-contract-info)
    {
        owner: CONTRACT_OWNER,
        paused: (var-get contract-paused),
        bridge-fee: (var-get bridge-fee-percentage)
    }
)

(define-read-only (is-bridge-authorized (bridge principal))
    (default-to false (map-get? authorized-bridges bridge))
)

(define-read-only (get-bridge-oracle (bridge principal))
    (map-get? bridge-oracles bridge)
)

(define-read-only (is-chain-supported (chain (string-ascii 32)))
    (default-to false (map-get? chain-supported chain))
)

(define-read-only (get-cross-chain-lock (sender principal) (nonce uint))
    (map-get? cross-chain-locks { sender: sender, nonce: nonce })
)

;; Private functions
(define-private (calculate-bridge-fee (amount uint))
    (/ (* amount (var-get bridge-fee-percentage)) u10000)
)

(define-private (validate-recipient (recipient (string-ascii 64)))
    (> (len recipient) u0)
)

(define-private (validate-chain (chain (string-ascii 32)))
    (and 
        (> (len chain) u0)
        (is-chain-supported chain)
    )
)

;; Public functions

;; Multi-send on same chain
(define-public (multi-send-stx (recipients (list 50 { recipient: principal, amount: uint })))
    (let
        (
            (total-sent (fold multi-send-stx-iter recipients (ok u0)))
        )
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        total-sent
    )
)

(define-private (multi-send-stx-iter 
    (transfer-data { recipient: principal, amount: uint })
    (previous-result (response uint uint))
)
    (match previous-result
        success (begin
            (asserts! (> (get amount transfer-data) u0) ERR_INVALID_AMOUNT)
            (asserts! (>= (stx-get-balance tx-sender) (get amount transfer-data)) ERR_INSUFFICIENT_BALANCE)
            (match (stx-transfer? (get amount transfer-data) tx-sender (get recipient transfer-data))
                transfer-success (ok (+ success (get amount transfer-data)))
                transfer-error (err transfer-error)
            )
        )
        error (err error)
    )
)

;; Cross-chain multi-send initialization
(define-public (initiate-cross-chain-send 
    (recipients (list 20 { recipient: (string-ascii 64), amount: uint, target-chain: (string-ascii 32) }))
    (bridge principal)
    (nonce uint)
)
    (let
        (
            (total-amount (fold sum-amounts recipients u0))
            (bridge-fee (calculate-bridge-fee total-amount))
            (total-with-fee (+ total-amount bridge-fee))
        )
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (is-bridge-authorized bridge) ERR_BRIDGE_NOT_SUPPORTED)
        (asserts! (>= (stx-get-balance tx-sender) total-with-fee) ERR_INSUFFICIENT_BALANCE)
        
        ;; Lock funds for cross-chain transfer
        (try! (stx-transfer? total-with-fee tx-sender (as-contract tx-sender)))
        
        ;; Process each recipient
        (try! (fold process-cross-chain-recipient recipients (ok u0)))
        
        ;; Emit cross-chain event
        (print {
            event: "cross-chain-initiated",
            sender: tx-sender,
            bridge: bridge,
            nonce: nonce,
            total-amount: total-amount,
            bridge-fee: bridge-fee,
            recipients: recipients
        })
        
        (ok nonce)
    )
)

(define-private (sum-amounts 
    (recipient-data { recipient: (string-ascii 64), amount: uint, target-chain: (string-ascii 32) })
    (sum uint)
)
    (+ sum (get amount recipient-data))
)

(define-private (process-cross-chain-recipient
    (recipient-data { recipient: (string-ascii 64), amount: uint, target-chain: (string-ascii 32) })
    (previous-result (response uint uint))
)
    (match previous-result
        success (begin
            (asserts! (validate-recipient (get recipient recipient-data)) ERR_INVALID_RECIPIENT)
            (asserts! (validate-chain (get target-chain recipient-data)) ERR_BRIDGE_NOT_SUPPORTED)
            (asserts! (> (get amount recipient-data) u0) ERR_INVALID_AMOUNT)
            (ok success)
        )
        error (err error)
    )
)

;; Oracle confirms cross-chain transfer completion
(define-public (confirm-cross-chain-transfer 
    (sender principal)
    (nonce uint)
    (success bool)
    (bridge principal)
)
    (let
        (
            (lock-data (unwrap! (get-cross-chain-lock sender nonce) ERR_CROSS_CHAIN_LOCKED))
            (expected-oracle (unwrap! (get-bridge-oracle bridge) ERR_BRIDGE_NOT_SUPPORTED))
        )
        ;; Only the specific oracle for this bridge can confirm
        (asserts! (is-eq tx-sender expected-oracle) ERR_UNAUTHORIZED)
        (asserts! (is-bridge-authorized bridge) ERR_BRIDGE_NOT_SUPPORTED)
        
        (if success
            ;; Transfer completed successfully on target chain
            (begin
                (map-delete cross-chain-locks { sender: sender, nonce: nonce })
                (print {
                    event: "cross-chain-completed",
                    sender: sender,
                    nonce: nonce,
                    oracle: tx-sender,
                    bridge: bridge
                })
                (ok true)
            )
            ;; Transfer failed, refund to sender
            (begin
                (try! (as-contract (stx-transfer? (get amount lock-data) tx-sender sender)))
                (map-delete cross-chain-locks { sender: sender, nonce: nonce })
                (print {
                    event: "cross-chain-refunded",
                    sender: sender,
                    nonce: nonce,
                    amount: (get amount lock-data),
                    bridge: bridge
                })
                (ok false)
            )
        )
    )
)

;; Emergency refund (time-locked)
(define-public (emergency-refund (nonce uint))
    (let
        (
            (lock-data (unwrap! (get-cross-chain-lock tx-sender nonce) ERR_CROSS_CHAIN_LOCKED))
            (time-elapsed (- block-height (get timestamp lock-data)))
        )
        ;; Allow refund after 1008 blocks (~1 week)
        (asserts! (>= time-elapsed u1008) ERR_CROSS_CHAIN_LOCKED)
        
        (try! (as-contract (stx-transfer? (get amount lock-data) tx-sender tx-sender)))
        (map-delete cross-chain-locks { sender: tx-sender, nonce: nonce })
        
        (print {
            event: "emergency-refund",
            sender: tx-sender,
            nonce: nonce,
            amount: (get amount lock-data)
        })
        
        (ok (get amount lock-data))
    )
)

;; Admin functions
(define-public (authorize-bridge (bridge principal) (oracle principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (map-set authorized-bridges bridge true)
        (map-set bridge-oracles bridge oracle)
        (ok true)
    )
)

(define-public (revoke-bridge (bridge principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (map-delete authorized-bridges bridge)
        (map-delete bridge-oracles bridge)
        (ok true)
    )
)

(define-public (add-supported-chain (chain (string-ascii 32)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (map-set chain-supported chain true)
        (ok true)
    )
)

(define-public (remove-supported-chain (chain (string-ascii 32)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (map-delete chain-supported chain)
        (ok true)
    )
)

(define-public (set-bridge-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (<= new-fee u1000) ERR_INVALID_AMOUNT) ;; Max 10%
        (var-set bridge-fee-percentage new-fee)
        (ok true)
    )
)

(define-public (toggle-contract-pause)
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (var-set contract-paused (not (var-get contract-paused)))
        (ok (var-get contract-paused))
    )
)

;; Initialize supported chains
(map-set chain-supported "ethereum" true)
(map-set chain-supported "bitcoin" true)
(map-set chain-supported "polygon" true)
(map-set chain-supported "avalanche" true)