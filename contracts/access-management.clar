;; Cultural Evolution Contract
;; Tracks consciousness transformation over time

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u500))
(define-constant err-not-found (err u501))

;; Data structures
(define-map evolution-snapshots
  { snapshot-id: uint }
  {
    heritage-id: uint,
    version: uint,
    changes: (string-ascii 500),
    contributor: principal,
    timestamp: uint,
    impact-score: uint
  }
)

(define-map heritage-evolution
  { heritage-id: uint }
  {
    current-version: uint,
    total-snapshots: uint,
    last-evolution: uint,
    evolution-rate: uint
  }
)

(define-map cultural-metrics
  { heritage-id: uint, metric-type: (string-ascii 30) }
  {
    value: uint,
    last-updated: uint,
    trend: (string-ascii 20)
  }
)

(define-data-var snapshot-counter uint u0)

;; Public functions
(define-public (record-evolution
  (heritage-id uint)
  (changes (string-ascii 500))
  (impact-score uint))
  (let (
    (snapshot-id (+ (var-get snapshot-counter) u1))
    (current-evolution (default-to
      { current-version: u0, total-snapshots: u0, last-evolution: u0, evolution-rate: u0 }
      (map-get? heritage-evolution { heritage-id: heritage-id })
    ))
    (new-version (+ (get current-version current-evolution) u1))
  )
    (map-set evolution-snapshots
      { snapshot-id: snapshot-id }
      {
        heritage-id: heritage-id,
        version: new-version,
        changes: changes,
        contributor: tx-sender,
        timestamp: block-height,
        impact-score: impact-score
      }
    )
    (map-set heritage-evolution
      { heritage-id: heritage-id }
      {
        current-version: new-version,
        total-snapshots: (+ (get total-snapshots current-evolution) u1),
        last-evolution: block-height,
        evolution-rate: (calculate-evolution-rate heritage-id)
      }
    )
    (var-set snapshot-counter snapshot-id)
    (ok snapshot-id)
  )
)

(define-public (update-cultural-metric
  (heritage-id uint)
  (metric-type (string-ascii 30))
  (value uint)
  (trend (string-ascii 20)))
  (begin
    (map-set cultural-metrics
      { heritage-id: heritage-id, metric-type: metric-type }
      {
        value: value,
        last-updated: block-height,
        trend: trend
      }
    )
    (ok true)
  )
)

;; Private functions
(define-private (calculate-evolution-rate (heritage-id uint))
  (match (map-get? heritage-evolution { heritage-id: heritage-id })
    evolution-data
      (if (> (get total-snapshots evolution-data) u0)
        (/ (* (get total-snapshots evolution-data) u100)
           (- block-height (get last-evolution evolution-data)))
        u0)
    u0
  )
)

;; Read-only functions
(define-read-only (get-evolution-snapshot (snapshot-id uint))
  (map-get? evolution-snapshots { snapshot-id: snapshot-id })
)

(define-read-only (get-heritage-evolution (heritage-id uint))
  (map-get? heritage-evolution { heritage-id: heritage-id })
)

(define-read-only (get-cultural-metric (heritage-id uint) (metric-type (string-ascii 30)))
  (map-get? cultural-metrics { heritage-id: heritage-id, metric-type: metric-type })
)

(define-read-only (get-evolution-timeline (heritage-id uint))
  (match (map-get? heritage-evolution { heritage-id: heritage-id })
    evolution-data (get total-snapshots evolution-data)
    u0
  )
)

(define-read-only (get-snapshot-count)
  (var-get snapshot-counter)
)
