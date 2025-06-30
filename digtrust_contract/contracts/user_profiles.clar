;; Enhanced UserProfiles Smart Contract
;; Purpose: Comprehensive user profile management with advanced features

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-username (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-invalid-score (err u105))
(define-constant err-account-suspended (err u106))
(define-constant err-insufficient-balance (err u107))
(define-constant err-invalid-tier (err u108))
(define-constant err-verification-required (err u109))
(define-constant err-rate-limit-exceeded (err u110))
(define-constant err-invalid-badge (err u111))
(define-constant err-subscription-expired (err u112))
(define-constant err-invalid-referral (err u113))
(define-constant err-kyc-required (err u114))
(define-constant err-geo-restricted (err u115))

;; Tier constants
(define-constant tier-bronze u1)
(define-constant tier-silver u2)
(define-constant tier-gold u3)
(define-constant tier-platinum u4)
(define-constant tier-diamond u5)

;; Badge constants
(define-constant badge-early-adopter u1)
(define-constant badge-power-uploader u2)
(define-constant badge-community-moderator u3)
(define-constant badge-verified-creator u4)
(define-constant badge-top-contributor u5)
(define-constant badge-security-researcher u6)

;; Data Variables
(define-data-var next-user-id uint u1)
(define-data-var platform-fee uint u1000000) ;; 1 STX in microSTX
(define-data-var referral-bonus uint u500000) ;; 0.5 STX bonus
(define-data-var kyc-required bool false)
(define-data-var platform-paused bool false)

;; Data Maps
;; Enhanced user profile storage
(define-map user-profiles
  { user-id: uint }
  {
    username: (string-ascii 50),
    display-name: (string-ascii 100),
    bio: (string-ascii 500),
    public-key: (buff 33),
    email-hash: (buff 32), ;; Hashed email for privacy
    avatar-url: (optional (string-ascii 200)),
    banner-url: (optional (string-ascii 200)),
    website: (optional (string-ascii 200)),
    location: (optional (string-ascii 100)),
    registration-block: uint,
    last-active: uint,
    last-updated: uint,
    reputation-score: uint,
    total-uploads: uint,
    total-downloads: uint,
    total-earned: uint,
    total-spent: uint,
    storage-used: uint, ;; in bytes
    bandwidth-used: uint, ;; in bytes
    is-active: bool,
    is-verified: bool,
    is-premium: bool,
    is-suspended: bool,
    suspension-reason: (optional (string-ascii 200)),
    kyc-status: uint, ;; 0=none, 1=pending, 2=approved, 3=rejected
    tier: uint,
    subscription-expires: uint,
    preferred-language: (string-ascii 10),
    timezone: (string-ascii 50),
    notification-settings: uint, ;; bitfield for preferences
    privacy-settings: uint, ;; bitfield for privacy options
    two-factor-enabled: bool,
    login-attempts: uint,
    last-login-attempt: uint
  }
)

;; User authentication and security
(define-map user-security
  { user-id: uint }
  {
    password-hash: (buff 32),
    salt: (buff 16),
    recovery-phrase-hash: (optional (buff 32)),
    backup-email-hash: (optional (buff 32)),
    security-questions: (list 3 (string-ascii 200)),
    failed-login-attempts: uint,
    last-password-change: uint,
    session-tokens: (list 5 (buff 32)),
    trusted-devices: (list 10 (buff 32)),
    api-keys: (list 5 { key-hash: (buff 32), permissions: uint, expires: uint })
  }
)

;; Social features
(define-map user-social
  { user-id: uint }
  {
    follower-count: uint,
    following-count: uint,
    post-count: uint,
    like-count: uint,
    share-count: uint,
    comment-count: uint,
    social-links: (list 10 { platform: (string-ascii 20), url: (string-ascii 200) })
  }
)

;; Following relationships
(define-map user-follows
  { follower-id: uint, following-id: uint }
  { follow-date: uint, notification-enabled: bool }
)

;; User badges and achievements
(define-map user-badges
  { user-id: uint, badge-id: uint }
  {
    earned-date: uint,
    badge-name: (string-ascii 50),
    badge-description: (string-ascii 200),
    badge-icon: (string-ascii 200),
    is-visible: bool
  }
)

;; Subscription management
(define-map user-subscriptions
  { user-id: uint }
  {
    plan-type: uint, ;; 1=basic, 2=pro, 3=enterprise
    start-date: uint,
    end-date: uint,
    auto-renew: bool,
    payment-method: (string-ascii 50),
    storage-limit: uint,
    bandwidth-limit: uint,
    upload-limit: uint,
    features: uint ;; bitfield for enabled features
  }
)

;; Referral system
(define-map user-referrals
  { referrer-id: uint }
  {
    total-referrals: uint,
    successful-referrals: uint,
    total-earned: uint,
    referral-code: (string-ascii 20)
  }
)

(define-map referral-relationships
  { referee-id: uint }
  { referrer-id: uint, referral-date: uint, bonus-paid: bool }
)

;; User transactions and payments
(define-map user-transactions
  { user-id: uint, tx-id: uint }
  {
    transaction-type: (string-ascii 20), ;; upload, download, subscription, etc.
    amount: uint,
    currency: (string-ascii 10),
    timestamp: uint,
    status: (string-ascii 20),
    description: (string-ascii 200)
  }
)

;; Content moderation
(define-map user-reports
  { reporter-id: uint, reported-id: uint, report-id: uint }
  {
    reason: (string-ascii 200),
    evidence: (optional (string-ascii 500)),
    timestamp: uint,
    status: (string-ascii 20), ;; pending, resolved, dismissed
    moderator-id: (optional uint),
    resolution: (optional (string-ascii 500))
  }
)

;; User preferences and settings
(define-map user-preferences
  { user-id: uint }
  {
    theme: (string-ascii 20),
    email-notifications: bool,
    push-notifications: bool,
    marketing-emails: bool,
    public-profile: bool,
    show-stats: bool,
    auto-backup: bool,
    compression-enabled: bool,
    encryption-enabled: bool,
    sharing-permissions: uint,
    download-permissions: uint
  }
)

;; Rate limiting
(define-map user-rate-limits
  { user-id: uint }
  {
    uploads-today: uint,
    downloads-today: uint,
    api-calls-today: uint,
    last-reset: uint,
    violations: uint
  }
)

;; Existing maps (keeping previous functionality)
(define-map principal-to-user-id { principal: principal } { user-id: uint })
(define-map username-to-user-id { username: (string-ascii 50) } { user-id: uint })
(define-map user-files
  { user-id: uint, file-id: uint }
  {
    file-hash: (buff 32),
    upload-block: uint,
    file-size: uint,
    file-type: (string-ascii 20),
    file-name: (string-ascii 200),
    is-public: bool,
    download-count: uint,
    price: uint,
    tags: (list 10 (string-ascii 30))
  }
)

(define-map user-activity
  { user-id: uint }
  {
    successful-uploads: uint,
    failed-uploads: uint,
    downloads-provided: uint,
    reports-received: uint,
    verified-uploads: uint,
    last-upload: uint,
    last-download: uint,
    streak-days: uint,
    total-points: uint
  }
)

;; Public Functions

;; Enhanced user registration with referral support
(define-public (register-user 
  (username (string-ascii 50)) 
  (display-name (string-ascii 100))
  (email-hash (buff 32))
  (public-key (buff 33))
  (referral-code (optional (string-ascii 20))))
  (let (
    (user-id (var-get next-user-id))
    (caller tx-sender)
    (referrer-id (match referral-code
      code (get-referrer-by-code code)
      none))
  )
    ;; Check if platform is paused
    (asserts! (not (var-get platform-paused)) err-unauthorized)
    
    ;; Validate inputs
    (asserts! (and (>= (len username) u3) (<= (len username) u50)) err-invalid-username)
    (asserts! (is-none (map-get? username-to-user-id { username: username })) err-already-exists)
    (asserts! (is-none (map-get? principal-to-user-id { principal: caller })) err-already-exists)
    
    ;; Create enhanced user profile
    (map-set user-profiles
      { user-id: user-id }
      {
        username: username,
        display-name: display-name,
        bio: "",
        public-key: public-key,
        email-hash: email-hash,
        avatar-url: none,
        banner-url: none,
        website: none,
        location: none,
        registration-block: block-height,
        last-active: block-height,
        last-updated: block-height,
        reputation-score: u100,
        total-uploads: u0,
        total-downloads: u0,
        total-earned: u0,
        total-spent: u0,
        storage-used: u0,
        bandwidth-used: u0,
        is-active: true,
        is-verified: false,
        is-premium: false,
        is-suspended: false,
        suspension-reason: none,
        kyc-status: u0,
        tier: tier-bronze,
        subscription-expires: u0,
        preferred-language: "en",
        timezone: "UTC",
        notification-settings: u255, ;; All notifications enabled
        privacy-settings: u0,
        two-factor-enabled: false,
        login-attempts: u0,
        last-login-attempt: u0
      }
    )
    
    ;; Set mappings
    (map-set principal-to-user-id { principal: caller } { user-id: user-id })
    (map-set username-to-user-id { username: username } { user-id: user-id })
    
    ;; Initialize other maps
    (initialize-user-data user-id)
    
    ;; Handle referral if provided
    (match referrer-id
      referrer (try! (process-referral referrer user-id))
      true
    )
    
    ;; Award early adopter badge if user ID is low
    (if (< user-id u1000)
      (try! (award-badge user-id badge-early-adopter))
      true
    )
    
    ;; Increment next user ID
    (var-set next-user-id (+ user-id u1))
    
    (ok user-id)
  )
)

;; Enhanced profile update with more fields
(define-public (update-profile-extended
  (display-name (string-ascii 100))
  (bio (string-ascii 500))
  (avatar-url (optional (string-ascii 200)))
  (website (optional (string-ascii 200)))
  (location (optional (string-ascii 100))))
  (let (
    (caller tx-sender)
    (user-lookup (map-get? principal-to-user-id { principal: caller }))
  )
    (match user-lookup
      user-data
      (let (
        (user-id (get user-id user-data))
        (current-profile (unwrap! (map-get? user-profiles { user-id: user-id }) err-not-found))
      )
        (asserts! (get is-active current-profile) err-account-suspended)
        
        (map-set user-profiles
          { user-id: user-id }
          (merge current-profile {
            display-name: display-name,
            bio: bio,
            avatar-url: avatar-url,
            website: website,
            location: location,
            last-updated: block-height
          })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Follow/unfollow users
(define-public (follow-user (target-user-id uint))
  (let (
    (caller tx-sender)
    (follower-lookup (map-get? principal-to-user-id { principal: caller }))
  )
    (match follower-lookup
      follower-data
      (let (
        (follower-id (get user-id follower-data))
        (existing-follow (map-get? user-follows { follower-id: follower-id, following-id: target-user-id }))
      )
        (asserts! (not (is-eq follower-id target-user-id)) err-unauthorized)
        (asserts! (is-none existing-follow) err-already-exists)
        
        ;; Create follow relationship
        (map-set user-follows
          { follower-id: follower-id, following-id: target-user-id }
          { follow-date: block-height, notification-enabled: true }
        )
        
        ;; Update social stats
        (update-social-stats follower-id "following" 1)
        (update-social-stats target-user-id "followers" 1)
        
        (ok true)
      )
      err-not-found
    )
  )
)

;; Subscribe to premium service
(define-public (subscribe-premium (plan-type uint) (duration uint))
  (let (
    (caller tx-sender)
    (user-lookup (map-get? principal-to-user-id { principal: caller }))
    (plan-cost (get-subscription-cost plan-type duration))
  )
    (match user-lookup
      user-data
      (let (
        (user-id (get user-id user-data))
        (current-profile (unwrap! (map-get? user-profiles { user-id: user-id }) err-not-found))
      )
        ;; Check if user has sufficient balance (simplified - in real implementation, handle STX transfer)
        (asserts! (>= (stx-get-balance caller) plan-cost) err-insufficient-balance)
        
        ;; Update subscription
        (map-set user-subscriptions
          { user-id: user-id }
          {
            plan-type: plan-type,
            start-date: block-height,
            end-date: (+ block-height duration),
            auto-renew: true,
            payment-method: "STX",
            storage-limit: (get-storage-limit plan-type),
            bandwidth-limit: (get-bandwidth-limit plan-type),
            upload-limit: (get-upload-limit plan-type),
            features: (get-plan-features plan-type)
          }
        )
        
        ;; Update profile
        (map-set user-profiles
          { user-id: user-id }
          (merge current-profile {
            is-premium: true,
            subscription-expires: (+ block-height duration),
            tier: (get-tier-for-plan plan-type)
          })
        )
        
        (ok true)
      )
      err-not-found
    )
  )
)

;; Report user for misconduct
(define-public (report-user (reported-user-id uint) (reason (string-ascii 200)) (evidence (optional (string-ascii 500))))
  (let (
    (caller tx-sender)
    (reporter-lookup (map-get? principal-to-user-id { principal: caller }))
    (report-id (+ (get-total-reports reported-user-id) u1))
  )
    (match reporter-lookup
      reporter-data
      (let (
        (reporter-id (get user-id reporter-data))
      )
        (asserts! (not (is-eq reporter-id reported-user-id)) err-unauthorized)
        
        ;; Create report
        (map-set user-reports
          { reporter-id: reporter-id, reported-id: reported-user-id, report-id: report-id }
          {
            reason: reason,
            evidence: evidence,
            timestamp: block-height,
            status: "pending",
            moderator-id: none,
            resolution: none
          }
        )
        
        ;; Update activity
        (update-user-activity reported-user-id "report-received")
        
        (ok report-id)
      )
      err-not-found
    )
  )
)

;; Award badge to user
(define-public (award-badge (user-id uint) (badge-id uint))
  (let (
    (caller tx-sender)
    (badge-info (get-badge-info badge-id))
  )
    ;; Only contract owner or authorized moderators can award badges
    (asserts! (is-eq caller contract-owner) err-unauthorized)
    
    (match badge-info
      info
      (begin
        (map-set user-badges
          { user-id: user-id, badge-id: badge-id }
          {
            earned-date: block-height,
            badge-name: (get name info),
            badge-description: (get description info),
            badge-icon: (get icon info),
            is-visible: true
          }
        )
        
        ;; Award reputation bonus
        (try! (update-reputation user-id 50 "badge-earned"))
        
        (ok true)
      )
      err-invalid-badge
    )
  )
)

;; Update user preferences
(define-public (update-preferences
  (theme (string-ascii 20))
  (email-notifications bool)
  (push-notifications bool)
  (public-profile bool))
  (let (
    (caller tx-sender)
    (user-lookup (map-get? principal-to-user-id { principal: caller }))
  )
    (match user-lookup
      user-data
      (let (
        (user-id (get user-id user-data))
      )
        (map-set user-preferences
          { user-id: user-id }
          {
            theme: theme,
            email-notifications: email-notifications,
            push-notifications: push-notifications,
            marketing-emails: false,
            public-profile: public-profile,
            show-stats: true,
            auto-backup: true,
            compression-enabled: true,
            encryption-enabled: true,
            sharing-permissions: u255,
            download-permissions: u255
          }
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Existing functions (keeping previous functionality)
(define-public (update-profile (new-username (string-ascii 50)) (new-public-key (buff 33)))
  (let (
    (caller tx-sender)
    (user-lookup (map-get? principal-to-user-id { principal: caller }))
  )
    (match user-lookup
      user-data
      (let (
        (user-id (get user-id user-data))
        (current-profile (unwrap! (map-get? user-profiles { user-id: user-id }) err-not-found))
        (current-username (get username current-profile))
      )
        (asserts! (and (>= (len new-username) u3) (<= (len new-username) u50)) err-invalid-username)
        
        (if (not (is-eq current-username new-username))
          (asserts! (is-none (map-get? username-to-user-id { username: new-username })) err-already-exists)
          true
        )
        
        (map-set user-profiles
          { user-id: user-id }
          (merge current-profile {
            username: new-username,
            public-key: new-public-key,
            last-updated: block-height
          })
        )
        
        (if (not (is-eq current-username new-username))
          (begin
            (map-delete username-to-user-id { username: current-username })
            (map-set username-to-user-id { username: new-username } { user-id: user-id })
          )
          true
        )
        
        (ok true)
      )
      err-not-found
    )
  )
)

(define-public (link-user-file (file-id uint) (file-hash (buff 32)) (file-size uint) (file-type (string-ascii 20)))
  (let (
    (caller tx-sender)
    (user-lookup (map-get? principal-to-user-id { principal: caller }))
  )
    (match user-lookup
      user-data
      (let (
        (user-id (get user-id user-data))
        (current-profile (unwrap! (map-get? user-profiles { user-id: user-id }) err-not-found))
      )
        ;; Check rate limits
        (try! (check-rate-limit user-id "upload"))
        
        (map-set user-files
          { user-id: user-id, file-id: file-id }
          {
            file-hash: file-hash,
            upload-block: block-height,
            file-size: file-size,
            file-type: file-type,
            file-name: "",
            is-public: true,
            download-count: u0,
            price: u0,
            tags: (list)
          }
        )
        
        (map-set user-profiles
          { user-id: user-id }
          (merge current-profile {
            total-uploads: (+ (get total-uploads current-profile) u1),
            storage-used: (+ (get storage-used current-profile) file-size),
            last-updated: block-height
          })
        )
        
        (update-user-activity user-id "upload-success")
        (ok true)
      )
      err-not-found
    )
  )
)

(define-public (update-reputation (target-user-id uint) (score-change int) (reason (string-ascii 50)))
  (let (
    (caller tx-sender)
    (current-profile (unwrap! (map-get? user-profiles { user-id: target-user-id }) err-not-found))
    (current-score (get reputation-score current-profile))
    (new-score (if (>= score-change 0)
                  (+ current-score (to-uint score-change))
                  (if (>= current-score (to-uint (* score-change -1)))
                    (- current-score (to-uint (* score-change -1)))
                    u0)))
  )
    (asserts! (or (is-eq caller contract-owner) 
                  (is-some (map-get? principal-to-user-id { principal: caller }))) 
              err-unauthorized)
    
    (map-set user-profiles
      { user-id: target-user-id }
      (merge current-profile {
        reputation-score: (if (> new-score u1000) u1000 new-score),
        last-updated: block-height
      })
    )
    
    ;; Update tier based on new reputation
    (update-user-tier-internal target-user-id new-score)
    
    (ok new-score)
  )
)

(define-public (record-download (uploader-user-id uint))
  (let (
    (current-profile (unwrap! (map-get? user-profiles { user-id: uploader-user-id }) err-not-found))
  )
    (map-set user-profiles
      { user-id: uploader-user-id }
      (merge current-profile {
        total-downloads: (+ (get total-downloads current-profile) u1),
        last-updated: block-height
      })
    )
    
    (update-user-activity uploader-user-id "download-provided")
    (ok true)
  )
)

(define-public (deactivate-account)
  (let (
    (caller tx-sender)
    (user-lookup (map-get? principal-to-user-id { principal: caller }))
  )
    (match user-lookup
      user-data
      (let (
        (user-id (get user-id user-data))
        (current-profile (unwrap! (map-get? user-profiles { user-id: user-id }) err-not-found))
      )
        (map-set user-profiles
          { user-id: user-id }
          (merge current-profile {
            is-active: false,
            last-updated: block-height
          })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Private Functions

(define-private (initialize-user-data (user-id uint))
  (begin
    (map-set user-activity
      { user-id: user-id }
      {
        successful-uploads: u0,
        failed-uploads: u0,
        downloads-provided: u0,
        reports-received: u0,
        verified-uploads: u0,
        last-upload: u0,
        last-download: u0,
        streak-days: u0,
        total-points: u0
      }
    )
    
    (map-set user-social
      { user-id: user-id }
      {
        follower-count: u0,
        following-count: u0,
        post-count: u0,
        like-count: u0,
        share-count: u0,
        comment-count: u0,
        social-links: (list)
      }
    )
    
    (map-set user-preferences
      { user-id: user-id }
      {
        theme: "light",
        email-notifications: true,
        push-notifications: true,
        marketing-emails: false,
        public-profile: true,
        show-stats: true,
        auto-backup: false,
        compression-enabled: true,
        encryption-enabled: false,
        sharing-permissions: u255,
        download-permissions: u255
      }
    )
    
    (map-set user-rate-limits
      { user-id: user-id }
      {
        uploads-today: u0,
        downloads-today: u0,
        api-calls-today: u0,
        last-reset: block-height,
        violations: u0
      }
    )
    
    true
  )
)

(define-private (update-user-activity (user-id uint) (activity-type (string-ascii 20)))
  (let (
    (current-activity (default-to 
      { successful-uploads: u0, failed-uploads: u0, downloads-provided: u0, reports-received: u0, verified-uploads: u0, last-upload: u0, last-download: u0, streak-days: u0, total-points: u0 }
      (map-get? user-activity { user-id: user-id })))
  )
    (map-set user-activity
      { user-id: user-id }
      (if (is-eq activity-type "upload-success")
        (merge current-activity { 
          successful-uploads: (+ (get successful-uploads current-activity) u1),
          last-upload: block-height,
          total-points: (+ (get total-points current-activity) u10)
        })
        (if (is-eq activity-type "download-provided")
          (merge current-activity { 
            downloads-provided: (+ (get downloads-provided current-activity) u1),
            last-download: block-height,
            total-points: (+ (get total-points current-activity) u5)
          })
          (if (is-eq activity-type "report-received")
            (merge current-activity { reports-received: (+ (get reports-received current-activity) u1) })
            current-activity))))
    true
  )
)

(define-private (process-referral (referrer-id uint) (referee-id uint))
  (let (
    (current-referrals (default-to 
      { total-referrals: u0, successful-referrals: u0, total-earned: u0, referral-code: "" }
      (map-get? user-referrals { referrer-id: referrer-id })))
  )
    ;; Update referrer stats
    (map-set user-referrals
      { referrer-id: referrer-id }
      (merge current-referrals {
        total-referrals: (+ (get total-referrals current-referrals) u1),
        successful-referrals: (+ (get successful-referrals current-referrals) u1),
        total-earned: (+ (get total-earned current-referrals) (var-get referral-bonus))
      })
    )
    
    ;; Create referral relationship
    (map-set referral-relationships
      { referee-id: referee-id }
      { referrer-id: referrer-id, referral-date: block-height, bonus-paid: false }
    )
    
    ;; Award reputation bonus to referrer
    (try! (update-reputation referrer-id 25 "successful-referral"))
    
    (ok true)
  )
)

(define-private (update-social-stats (user-id uint) (stat-type (string-ascii 20)) (change int))
  (let (
    (current-social (default-to 
      { follower-count: u0, following-count: u0, post-count: u0, like-count: u0, share-count: u0, comment-count: u0, social-links: (list) }
      (map-get? user-social { user-id: user-id })))
  )
    (map-set user-social
      { user-id: user-id }
      (if (is-eq stat-type "followers")
        (merge current-social { follower-count: (+ (get follower-count current-social) (to-uint change)) })
        (if (is-eq stat-type "following")
          (merge current-social { following-count: (+ (get following-count current-social) (to-uint change)) })
          current-social))
    )
    true
  )
)

(define-private (check-rate-limit (user-id uint) (action (string-ascii 20)))
  (let (
    (current-limits (default-to 
      { uploads-today: u0, downloads-today: u0, api-calls-today: u0, last-reset: u0, violations: u0 }
      (map-get? user-rate-limits { user-id: user-id })))
    (blocks-per-day u144) ;; Approximately 144 blocks per day
    (days-since-reset (/ (- block-height (get last-reset current-limits)) blocks-per-day))
  )
    ;; Reset counters if a day has passed
    (let (
      (reset-limits (if (>= days-since-reset u1)
        { uploads-today: u0, downloads-today: u0, api-calls-today: u0, last-reset: block-height, violations: (get violations current-limits) }
        current-limits))
    )
      (if (is-eq action "upload")
        (if (< (get uploads-today reset-limits) u50) ;; 50 uploads per day limit
          (begin
            (map-set user-rate-limits
              { user-id: user-id }
              (merge reset-limits { uploads-today: (+ (get uploads-today reset-limits) u1) })
            )
            (ok true)
          )
          err-rate-limit-exceeded
        )
        (if (is-eq action "download")
          (if (< (get downloads-today reset-limits) u200) ;; 200 downloads per day limit
            (begin
              (map-set user-rate-limits
                { user-id: user-id }
                (merge reset-limits { downloads-today: (+ (get downloads-today reset-limits) u1) })
              )
              (ok true)
            )
            err-rate-limit-exceeded
          )
          (ok true) ;; No limit for other actions
        )
      )
    )
  )
)

(define-private (update-user-tier-internal (user-id uint) (reputation-score uint))
  (let (
    (current-profile (unwrap-panic (map-get? user-profiles { user-id: user-id })))
    (new-tier (if (>= reputation-score u800) tier-diamond
                (if (>= reputation-score u600) tier-platinum
                  (if (>= reputation-score u400) tier-gold
                    (if (>= reputation-score u200) tier-silver
                      tier-bronze)))))
  )
    (map-set user-profiles
      { user-id: user-id }
      (merge current-profile { tier: new-tier })
    )
    new-tier
  )
)

(define-private (get-referrer-by-code (referral-code (string-ascii 20)))
  (let (
    ;; In a real implementation, you'd search through referral codes
    ;; This is a simplified version
    (dummy-referrer-id u1)
  )
    (if (> (len referral-code) u0) 
      (some dummy-referrer-id)
      none)
  )
)

(define-private (get-badge-info (badge-id uint))
  (if (is-eq badge-id badge-early-adopter)
    (some (tuple (name "Early Adopter") (description "One of the first 1000 users") (icon "trophy")))
    (if (is-eq badge-id badge-power-uploader)
      (some (tuple (name "Power Uploader") (description "Uploaded over 100 files") (icon "upload")))
      (if (is-eq badge-id badge-community-moderator)
        (some (tuple (name "Community Moderator") (description "Trusted community member") (icon "shield")))
        (if (is-eq badge-id badge-verified-creator)
          (some (tuple (name "Verified Creator") (description "Verified content creator") (icon "check")))
          (if (is-eq badge-id badge-top-contributor)
            (some (tuple (name "Top Contributor") (description "Top 1% contributor") (icon "star")))
            (if (is-eq badge-id badge-security-researcher)
              (some (tuple (name "Security Researcher") (description "Found security vulnerabilities") (icon "lock")))
              none))))))
)

(define-private (get-subscription-cost (plan-type uint) (duration uint))
  (let (
    (base-cost (if (is-eq plan-type u1) u5000000 ;; 5 STX for basic
                  (if (is-eq plan-type u2) u15000000 ;; 15 STX for pro
                    u50000000))) ;; 50 STX for enterprise
  )
    (* base-cost duration)
  )
)

(define-private (get-storage-limit (plan-type uint))
  (if (is-eq plan-type u1) u1000000000 ;; 1GB for basic
    (if (is-eq plan-type u2) u10000000000 ;; 10GB for pro
      u100000000000)) ;; 100GB for enterprise
)

(define-private (get-bandwidth-limit (plan-type uint))
  (if (is-eq plan-type u1) u10000000000 ;; 10GB for basic
    (if (is-eq plan-type u2) u100000000000 ;; 100GB for pro
      u1000000000000)) ;; 1TB for enterprise
)

(define-private (get-upload-limit (plan-type uint))
  (if (is-eq plan-type u1) u50 ;; 50 uploads per day for basic
    (if (is-eq plan-type u2) u200 ;; 200 uploads per day for pro
      u1000)) ;; 1000 uploads per day for enterprise
)

(define-private (get-plan-features (plan-type uint))
  (if (is-eq plan-type u1) u15 ;; Basic features bitfield
    (if (is-eq plan-type u2) u63 ;; Pro features bitfield
      u255)) ;; Enterprise features bitfield (all features)
)

(define-private (get-tier-for-plan (plan-type uint))
  (if (is-eq plan-type u1) tier-silver
    (if (is-eq plan-type u2) tier-gold
      tier-platinum))
)

(define-private (get-total-reports (user-id uint))
  ;; Simplified count - in real implementation, iterate through reports
  u0
)

;; Read-only Functions

;; Enhanced user profile getters
(define-read-only (get-user-profile (user-id uint))
  (map-get? user-profiles { user-id: user-id })
)

(define-read-only (get-user-profile-by-principal (user-principal principal))
  (match (map-get? principal-to-user-id { principal: user-principal })
    user-data (map-get? user-profiles { user-id: (get user-id user-data) })
    none
  )
)

(define-read-only (get-user-profile-by-username (username (string-ascii 50)))
  (match (map-get? username-to-user-id { username: username })
    user-data (map-get? user-profiles { user-id: (get user-id user-data) })
    none
  )
)

(define-read-only (get-user-id-by-principal (user-principal principal))
  (map-get? principal-to-user-id { principal: user-principal })
)

(define-read-only (get-user-file (user-id uint) (file-id uint))
  (map-get? user-files { user-id: user-id, file-id: file-id })
)

(define-read-only (get-user-activity (user-id uint))
  (map-get? user-activity { user-id: user-id })
)

(define-read-only (get-user-social-stats (user-id uint))
  (map-get? user-social { user-id: user-id })
)

(define-read-only (get-user-badges (user-id uint))
  ;; Returns first badge for simplicity - in real implementation, return all badges
  (map-get? user-badges { user-id: user-id, badge-id: badge-early-adopter })
)

(define-read-only (get-user-subscription (user-id uint))
  (map-get? user-subscriptions { user-id: user-id })
)

(define-read-only (get-user-preferences (user-id uint))
  (map-get? user-preferences { user-id: user-id })
)

(define-read-only (get-user-rate-limits (user-id uint))
  (map-get? user-rate-limits { user-id: user-id })
)

(define-read-only (is-following (follower-id uint) (following-id uint))
  (is-some (map-get? user-follows { follower-id: follower-id, following-id: following-id }))
)

(define-read-only (is-username-available (username (string-ascii 50)))
  (is-none (map-get? username-to-user-id { username: username }))
)

(define-read-only (get-total-users)
  (- (var-get next-user-id) u1)
)

(define-read-only (calculate-reputation-score (user-id uint))
  (match (map-get? user-activity { user-id: user-id })
    activity
    (let (
      (successful-uploads (get successful-uploads activity))
      (failed-uploads (get failed-uploads activity))
      (downloads-provided (get downloads-provided activity))
      (reports-received (get reports-received activity))
      (verified-uploads (get verified-uploads activity))
      (upload-success-rate (if (> (+ successful-uploads failed-uploads) u0)
                             (/ (* successful-uploads u100) (+ successful-uploads failed-uploads))
                             u100))
      (base-score u100)
      (upload-bonus (* successful-uploads u5))
      (verification-bonus (* verified-uploads u10))
      (download-bonus (* downloads-provided u2))
      (report-penalty (* reports-received u20))
      (calculated-score (+ base-score upload-bonus verification-bonus download-bonus))
      (final-score (if (>= calculated-score report-penalty)
                     (- calculated-score report-penalty)
                     u0))
    )
      (if (> final-score u1000) u1000 final-score)
    )
    u100
  )
)

(define-read-only (get-user-tier-name (tier uint))
  (if (is-eq tier tier-bronze) "Bronze"
    (if (is-eq tier tier-silver) "Silver"
      (if (is-eq tier tier-gold) "Gold"
        (if (is-eq tier tier-platinum) "Platinum"
          (if (is-eq tier tier-diamond) "Diamond"
            "Unknown")))))
)

(define-read-only (is-premium-user (user-id uint))
  (match (map-get? user-profiles { user-id: user-id })
    profile (and (get is-premium profile) (> (get subscription-expires profile) block-height))
    false
  )
)

(define-read-only (get-platform-stats)
  {
    total-users: (get-total-users),
    platform-fee: (var-get platform-fee),
    referral-bonus: (var-get referral-bonus),
    kyc-required: (var-get kyc-required),
    platform-paused: (var-get platform-paused)
  }
)

;; Admin Functions (Contract Owner Only)

(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set platform-fee new-fee)
    (ok true)
  )
)

(define-public (pause-platform (paused bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set platform-paused paused)
    (ok true)
  )
)

(define-public (suspend-user (user-id uint) (reason (string-ascii 200)))
  (let (
    (current-profile (unwrap! (map-get? user-profiles { user-id: user-id }) err-not-found))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set user-profiles
      { user-id: user-id }
      (merge current-profile {
        is-suspended: true,
        suspension-reason: (some reason)
      })
    )
    (ok true)
  )
)

(define-public (verify-user (user-id uint))
  (let (
    (current-profile (unwrap! (map-get? user-profiles { user-id: user-id }) err-not-found))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set user-profiles
      { user-id: user-id }
      (merge current-profile { is-verified: true })
    )
    
    ;; Award verification badge
    (try! (award-badge user-id badge-verified-creator))
    
    (ok true)
  )
)