(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-MACHINE-NOT-FOUND (err u101))
(define-constant ERR-SUPPLIER-NOT-FOUND (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-QUOTA-NOT-MET (err u104))
(define-constant ERR-ALREADY-EXISTS (err u105))
(define-constant ERR-MACHINE-INACTIVE (err u106))
(define-constant ERR-INSUFFICIENT-BALANCE (err u107))
(define-constant ERR-MAINTENANCE-REQUIRED (err u108))

(define-data-var contract-owner principal tx-sender)
(define-data-var total-machines uint u0)
(define-data-var total-suppliers uint u0)

(define-map machines
  { machine-id: uint }
  {
    owner: principal,
    name: (string-ascii 50),
    quota: uint,
    production: uint,
    active: bool,
    created-at: uint
  }
)

(define-map suppliers
  { supplier-id: uint }
  {
    address: principal,
    name: (string-ascii 50),
    payment-amount: uint,
    quota-requirement: uint,
    paid: bool,
    created-at: uint
  }
)

(define-map production-logs
  { log-id: uint }
  {
    machine-id: uint,
    amount: uint,
    timestamp: uint,
    block-height: uint
  }
)

(define-map machine-suppliers
  { machine-id: uint, supplier-id: uint }
  { active: bool }
)

(define-data-var next-log-id uint u1)
(define-data-var next-maintenance-id uint u1)

(define-map machine-maintenance
  { machine-id: uint }
  {
    service-points: uint,
    service-threshold: uint,
    last-service-block: uint,
    total-services: uint,
    requires-maintenance: bool
  }
)

(define-map maintenance-history
  { maintenance-id: uint }
  {
    machine-id: uint,
    service-points-at-service: uint,
    serviced-by: principal,
    service-block: uint,
    notes: (string-ascii 100)
  }
)

(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
    (var-set contract-owner new-owner)
    (ok true)
  )
)

(define-public (register-machine (name (string-ascii 50)) (quota uint))
  (let
    (
      (machine-id (+ (var-get total-machines) u1))
    )
    (asserts! (> quota u0) ERR-INVALID-AMOUNT)
    (asserts! (is-none (map-get? machines { machine-id: machine-id })) ERR-ALREADY-EXISTS)
    (map-set machines
      { machine-id: machine-id }
      {
        owner: tx-sender,
        name: name,
        quota: quota,
        production: u0,
        active: true,
        created-at: stacks-block-height
      }
    )
    (map-set machine-maintenance
      { machine-id: machine-id }
      {
        service-points: u0,
        service-threshold: u1000,
        last-service-block: stacks-block-height,
        total-services: u0,
        requires-maintenance: false
      }
    )
    (var-set total-machines machine-id)
    (ok machine-id)
  )
)

(define-public (register-supplier (name (string-ascii 50)) (payment-amount uint) (quota-requirement uint))
  (let
    (
      (supplier-id (+ (var-get total-suppliers) u1))
    )
    (asserts! (> payment-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (> quota-requirement u0) ERR-INVALID-AMOUNT)
    (asserts! (is-none (map-get? suppliers { supplier-id: supplier-id })) ERR-ALREADY-EXISTS)
    (map-set suppliers
      { supplier-id: supplier-id }
      {
        address: tx-sender,
        name: name,
        payment-amount: payment-amount,
        quota-requirement: quota-requirement,
        paid: false,
        created-at: stacks-block-height
      }
    )
    (var-set total-suppliers supplier-id)
    (ok supplier-id)
  )
)

(define-public (link-supplier-to-machine (machine-id uint) (supplier-id uint))
  (let
    (
      (machine (unwrap! (map-get? machines { machine-id: machine-id }) ERR-MACHINE-NOT-FOUND))
      (supplier (unwrap! (map-get? suppliers { supplier-id: supplier-id }) ERR-SUPPLIER-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get owner machine)) ERR-UNAUTHORIZED)
    (map-set machine-suppliers
      { machine-id: machine-id, supplier-id: supplier-id }
      { active: true }
    )
    (ok true)
  )
)

(define-public (update-production (machine-id uint) (amount uint))
  (let
    (
      (machine (unwrap! (map-get? machines { machine-id: machine-id }) ERR-MACHINE-NOT-FOUND))
      (log-id (var-get next-log-id))
      (new-production (+ (get production machine) amount))
      (maintenance (unwrap! (map-get? machine-maintenance { machine-id: machine-id }) ERR-MACHINE-NOT-FOUND))
      (new-service-points (+ (get service-points maintenance) amount))
      (needs-service (>= new-service-points (get service-threshold maintenance)))
    )
    (asserts! (is-eq tx-sender (get owner machine)) ERR-UNAUTHORIZED)
    (asserts! (get active machine) ERR-MACHINE-INACTIVE)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    
    (map-set machines
      { machine-id: machine-id }
      (merge machine { production: new-production })
    )
    
    (map-set machine-maintenance
      { machine-id: machine-id }
      (merge maintenance { 
        service-points: new-service-points,
        requires-maintenance: needs-service
      })
    )
    
    (map-set production-logs
      { log-id: log-id }
      {
        machine-id: machine-id,
        amount: amount,
        timestamp: stacks-block-height,
        block-height: stacks-block-height
      }
    )
    
    (var-set next-log-id (+ log-id u1))
    (ok new-production)
  )
)

(define-public (toggle-machine-status (machine-id uint))
  (let
    (
      (machine (unwrap! (map-get? machines { machine-id: machine-id }) ERR-MACHINE-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get owner machine)) ERR-UNAUTHORIZED)
    (map-set machines
      { machine-id: machine-id }
      (merge machine { active: (not (get active machine)) })
    )
    (ok (not (get active machine)))
  )
)

(define-public (process-supplier-payment (machine-id uint) (supplier-id uint))
  (let
    (
      (machine (unwrap! (map-get? machines { machine-id: machine-id }) ERR-MACHINE-NOT-FOUND))
      (supplier (unwrap! (map-get? suppliers { supplier-id: supplier-id }) ERR-SUPPLIER-NOT-FOUND))
      (link (unwrap! (map-get? machine-suppliers { machine-id: machine-id, supplier-id: supplier-id }) ERR-SUPPLIER-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
    (asserts! (get active link) ERR-UNAUTHORIZED)
    (asserts! (not (get paid supplier)) ERR-ALREADY-EXISTS)
    (asserts! (>= (get production machine) (get quota-requirement supplier)) ERR-QUOTA-NOT-MET)
    
    (try! (stx-transfer? (get payment-amount supplier) tx-sender (get address supplier)))
    
    (map-set suppliers
      { supplier-id: supplier-id }
      (merge supplier { paid: true })
    )
    
    (ok true)
  )
)

(define-public (reset-machine-production (machine-id uint))
  (let
    (
      (machine (unwrap! (map-get? machines { machine-id: machine-id }) ERR-MACHINE-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get owner machine)) ERR-UNAUTHORIZED)
    (map-set machines
      { machine-id: machine-id }
      (merge machine { production: u0 })
    )
    (ok true)
  )
)

(define-public (update-machine-quota (machine-id uint) (new-quota uint))
  (let
    (
      (machine (unwrap! (map-get? machines { machine-id: machine-id }) ERR-MACHINE-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get owner machine)) ERR-UNAUTHORIZED)
    (asserts! (> new-quota u0) ERR-INVALID-AMOUNT)
    (map-set machines
      { machine-id: machine-id }
      (merge machine { quota: new-quota })
    )
    (ok true)
  )
)

(define-read-only (get-machine (machine-id uint))
  (map-get? machines { machine-id: machine-id })
)

(define-read-only (get-supplier (supplier-id uint))
  (map-get? suppliers { supplier-id: supplier-id })
)

(define-read-only (get-production-log (log-id uint))
  (map-get? production-logs { log-id: log-id })
)

(define-read-only (get-machine-supplier-link (machine-id uint) (supplier-id uint))
  (map-get? machine-suppliers { machine-id: machine-id, supplier-id: supplier-id })
)

(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

(define-read-only (get-total-machines)
  (var-get total-machines)
)

(define-read-only (get-total-suppliers)
  (var-get total-suppliers)
)

(define-read-only (check-quota-status (machine-id uint))
  (match (map-get? machines { machine-id: machine-id })
    machine (ok {
      quota: (get quota machine),
      production: (get production machine),
      quota-met: (>= (get production machine) (get quota machine)),
      percentage: (/ (* (get production machine) u100) (get quota machine))
    })
    ERR-MACHINE-NOT-FOUND
  )
)

(define-read-only (can-process-payment (machine-id uint) (supplier-id uint))
  (match (map-get? machines { machine-id: machine-id })
    machine (match (map-get? suppliers { supplier-id: supplier-id })
      supplier (ok {
        quota-met: (>= (get production machine) (get quota-requirement supplier)),
        already-paid: (get paid supplier),
        can-pay: (and 
          (>= (get production machine) (get quota-requirement supplier))
          (not (get paid supplier))
        )
      })
      ERR-SUPPLIER-NOT-FOUND
    )
    ERR-MACHINE-NOT-FOUND
  )
)

(define-read-only (get-machine-production-stats (machine-id uint))
  (match (map-get? machines { machine-id: machine-id })
    machine (ok {
      total-production: (get production machine),
      quota: (get quota machine),
      active: (get active machine),
      owner: (get owner machine)
    })
    ERR-MACHINE-NOT-FOUND
  )
)

(define-public (perform-machine-service (machine-id uint) (notes (string-ascii 100)))
  (let
    (
      (machine (unwrap! (map-get? machines { machine-id: machine-id }) ERR-MACHINE-NOT-FOUND))
      (maintenance (unwrap! (map-get? machine-maintenance { machine-id: machine-id }) ERR-MACHINE-NOT-FOUND))
      (maintenance-id (var-get next-maintenance-id))
    )
    (asserts! (is-eq tx-sender (get owner machine)) ERR-UNAUTHORIZED)
    (asserts! (get requires-maintenance maintenance) ERR-MAINTENANCE-REQUIRED)
    
    (map-set machine-maintenance
      { machine-id: machine-id }
      {
        service-points: u0,
        service-threshold: (get service-threshold maintenance),
        last-service-block: stacks-block-height,
        total-services: (+ (get total-services maintenance) u1),
        requires-maintenance: false
      }
    )
    
    (map-set maintenance-history
      { maintenance-id: maintenance-id }
      {
        machine-id: machine-id,
        service-points-at-service: (get service-points maintenance),
        serviced-by: tx-sender,
        service-block: stacks-block-height,
        notes: notes
      }
    )
    
    (var-set next-maintenance-id (+ maintenance-id u1))
    (ok maintenance-id)
  )
)

(define-public (update-service-threshold (machine-id uint) (new-threshold uint))
  (let
    (
      (machine (unwrap! (map-get? machines { machine-id: machine-id }) ERR-MACHINE-NOT-FOUND))
      (maintenance (unwrap! (map-get? machine-maintenance { machine-id: machine-id }) ERR-MACHINE-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get owner machine)) ERR-UNAUTHORIZED)
    (asserts! (> new-threshold u0) ERR-INVALID-AMOUNT)
    
    (map-set machine-maintenance
      { machine-id: machine-id }
      (merge maintenance { service-threshold: new-threshold })
    )
    (ok true)
  )
)

(define-read-only (get-machine-maintenance-status (machine-id uint))
  (map-get? machine-maintenance { machine-id: machine-id })
)

(define-read-only (get-maintenance-record (maintenance-id uint))
  (map-get? maintenance-history { maintenance-id: maintenance-id })
)

(define-read-only (check-maintenance-needed (machine-id uint))
  (match (map-get? machine-maintenance { machine-id: machine-id })
    maintenance (ok {
      service-points: (get service-points maintenance),
      service-threshold: (get service-threshold maintenance),
      requires-maintenance: (get requires-maintenance maintenance),
      total-services: (get total-services maintenance),
      blocks-since-service: (- stacks-block-height (get last-service-block maintenance))
    })
    ERR-MACHINE-NOT-FOUND
  )
)
