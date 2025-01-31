
;; title: user_data_control
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

;; User Data Control & Consent Management
;; Handles data vault references, permissions, and consent management

;; Data structures
(define-map user-vaults
    principal
    {
        ipfs-hash: (string-ascii 64),
        encryption-key: (string-ascii 64),
        created-at: uint,
        last-updated: uint
    }
)

(define-map data-permissions
    {
        owner: principal,
        requester: principal,
        data-id: (string-ascii 36)
    }
    {
        granted: bool,
        purpose: (string-ascii 64),
        expiry: uint,
        access-count: uint
    }
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-EXPIRY (err u101))
(define-constant ERR-PERMISSION-NOT-FOUND (err u102))

;; Read-only functions
(define-read-only (get-user-vault (user principal))
    (map-get? user-vaults user)
)

(define-read-only (get-permission (owner principal) (requester principal) (data-id (string-ascii 36)))
    (map-get? data-permissions {owner: owner, requester: requester, data-id: data-id})
)

(define-read-only (check-permission (owner principal) (requester principal) (data-id (string-ascii 36)))
    (match (map-get? data-permissions {owner: owner, requester: requester, data-id: data-id})
        permission (let
            (
                (is-valid (and
                    (get granted permission)
                    (< block-height (get expiry permission))
                ))
            )
            (ok is-valid)
        )
        (err ERR-PERMISSION-NOT-FOUND)
    )
)

;; Public functions
(define-public (register-vault (ipfs-hash (string-ascii 64)) (encryption-key (string-ascii 64)))
    (let
        (
            (user tx-sender)
            (vault-data {
                ipfs-hash: ipfs-hash,
                encryption-key: encryption-key,
                created-at: block-height,
                last-updated: block-height
            })
        )
        (ok (map-set user-vaults user vault-data))
    )
)

(define-public (update-vault (ipfs-hash (string-ascii 64)) (encryption-key (string-ascii 64)))
    (let
        (
            (user tx-sender)
            (existing-vault (unwrap! (map-get? user-vaults user) ERR-NOT-AUTHORIZED))
            (updated-vault {
                ipfs-hash: ipfs-hash,
                encryption-key: encryption-key,
                created-at: (get created-at existing-vault),
                last-updated: block-height
            })
        )
        (ok (map-set user-vaults user updated-vault))
    )
)

(define-public (grant-permission
    (requester principal)
    (data-id (string-ascii 36))
    (purpose (string-ascii 64))
    (duration uint))
    (let
        (
            (owner tx-sender)
            (expiry (+ block-height duration))
            (permission-data {
                granted: true,
                purpose: purpose,
                expiry: expiry,
                access-count: u0
            })
        )
        (asserts! (> duration u0) ERR-INVALID-EXPIRY)
        (ok (map-set data-permissions
            {owner: owner, requester: requester, data-id: data-id}
            permission-data
        ))
    )
)

(define-public (revoke-permission (requester principal) (data-id (string-ascii 36)))
    (let
        (
            (owner tx-sender)
            (existing-permission (unwrap! 
                (map-get? data-permissions {owner: owner, requester: requester, data-id: data-id})
                ERR-PERMISSION-NOT-FOUND
            ))
            (revoked-permission {
                granted: false,
                purpose: (get purpose existing-permission),
                expiry: block-height,
                access-count: (get access-count existing-permission)
            })
        )
        (ok (map-set data-permissions
            {owner: owner, requester: requester, data-id: data-id}
            revoked-permission
        ))
    )
)

(define-public (record-access (owner principal) (data-id (string-ascii 36)))
    (let
        (
            (requester tx-sender)
            (permission-key {owner: owner, requester: requester, data-id: data-id})
            (existing-permission (unwrap! (map-get? data-permissions permission-key) ERR-PERMISSION-NOT-FOUND))
        )
        (asserts! (get granted existing-permission) ERR-NOT-AUTHORIZED)
        (asserts! (< block-height (get expiry existing-permission)) ERR-NOT-AUTHORIZED)
        (ok (map-set data-permissions
            permission-key
            (merge existing-permission {access-count: (+ (get access-count existing-permission) u1)})
        ))
    )
)