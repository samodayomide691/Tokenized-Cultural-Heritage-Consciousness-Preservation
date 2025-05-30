;; Access Management Contract
;; Controls preserved consciousness access

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-unauthorized (err u301))
(define-constant err-not-found (err u302))

;; Data structures
(define-map access-permissions
  { user: principal, heritage-id: uint }
  {
    access-level: (string-ascii 20),
    granted-by: principal,
    granted-at: uint,
    expires-at: uint
  }
)

(define-map access-logs
  { log-id: uint }
  {
    user: principal,
    heritage-id: uint,
    action: (string-ascii 50),
    timestamp: uint
  }
)

(define-data-var log-counter uint u0)

;; Public functions
(define-public (grant-access
  (user principal)
  (heritage-id uint)
  (access-level (string-ascii 20))
  (duration uint))
  (begin
    (map-set access-permissions
      { user: user, heritage-id: heritage-id }
      {
        access-level: access-level,
        granted-by: tx-sender,
        granted-at: block-height,
        expires-at: (+ block-height duration)
      }
    )
    (log-access user heritage-id "access-granted")
    (ok true)
  )
)

(define-public (revoke-access (user principal) (heritage-id uint))
  (begin
    (map-delete access-permissions { user: user, heritage-id: heritage-id })
    (log-access user heritage-id "access-revoked")
    (ok true)
  )
)

(define-public (access-consciousness (heritage-id uint))
  (let ((permission (unwrap! (map-get? access-permissions { user: tx-sender, heritage-id: heritage-id }) err-unauthorized)))
    (if (> (get expires-at permission) block-height)
      (begin
        (log-access tx-sender heritage-id "consciousness-accessed")
        (ok true)
      )
      err-unauthorized
    )
  )
)

;; Private functions
(define-private (log-access (user principal) (heritage-id uint) (action (string-ascii 50)))
  (let ((log-id (+ (var-get log-counter) u1)))
    (map-set access-logs
      { log-id: log-id }
      {
        user: user,
        heritage-id: heritage-id,
        action: action,
        timestamp: block-height
      }
    )
    (var-set log-counter log-id)
    log-id
  )
)

;; Read-only functions
(define-read-only (check-access (user principal) (heritage-id uint))
  (match (map-get? access-permissions { user: user, heritage-id: heritage-id })
    permission (> (get expires-at permission) block-height)
    false
  )
)

(define-read-only (get-access-permission (user principal) (heritage-id uint))
  (map-get? access-permissions { user: user, heritage-id: heritage-id })
)

(define-read-only (get-access-log (log-id uint))
  (map-get? access-logs { log-id: log-id })
)
