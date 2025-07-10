;; ThreadMint - Fashion Authentication System
;; This contract manages fashion item authentication and ownership tracking

(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-item-not-found (err u101))
(define-constant err-already-certified (err u102))
(define-constant err-not-owner (err u103))
(define-constant err-invalid-brand (err u104))
(define-constant err-invalid-input (err u105))

;; Storage for fashion items
(define-map fashion-items
  { item-id: uint }
  {
    brand: (string-ascii 50),
    model: (string-ascii 100),
    size: (string-ascii 10),
    color: (string-ascii 20),
    material: (string-ascii 100),
    manufacturing-date: uint,
    owner: principal,
    certified: bool,
    authenticity-score: uint
  }
)

;; Certified brands
(define-map certified-brands
  { brand: (string-ascii 50) }
  { authorized: bool, created-at: uint }
)

;; Ownership history
(define-map ownership-history
  { item-id: uint, sequence: uint }
  { 
    from: principal,
    to: principal,
    timestamp: uint,
    price: uint
  }
)

;; Data variables
(define-data-var next-item-id uint u1)
(define-data-var total-certified-items uint u0)

;; Read-only functions
(define-read-only (get-item-details (item-id uint))
  (map-get? fashion-items { item-id: item-id })
)

(define-read-only (get-ownership-history (item-id uint) (sequence uint))
  (map-get? ownership-history { item-id: item-id, sequence: sequence })
)

(define-read-only (is-brand-certified (brand (string-ascii 50)))
  (default-to false (get authorized (map-get? certified-brands { brand: brand })))
)

(define-read-only (get-total-certified-items)
  (var-get total-certified-items)
)

(define-read-only (get-next-item-id)
  (var-get next-item-id)
)

(define-read-only (is-item-owner (item-id uint) (user principal))
  (match (map-get? fashion-items { item-id: item-id })
    item-data (is-eq (get owner item-data) user)
    false
  )
)

;; Helper function to validate string inputs
(define-private (validate-string-input (input (string-ascii 100)))
  (and (> (len input) u0) (<= (len input) u100))
)

(define-private (validate-brand-input (input (string-ascii 50)))
  (and (> (len input) u0) (<= (len input) u50))
)

(define-private (validate-size-input (input (string-ascii 10)))
  (and (> (len input) u0) (<= (len input) u10))
)

(define-private (validate-color-input (input (string-ascii 20)))
  (and (> (len input) u0) (<= (len input) u20))
)

(define-private (validate-principal (input principal))
  (not (is-eq input (as-contract tx-sender)))
)

(define-private (validate-item-id (item-id uint))
  (and (> item-id u0) (< item-id (var-get next-item-id)))
)

;; Public functions
(define-public (register-brand (brand (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (validate-brand-input brand) err-invalid-input)
    (map-set certified-brands
      { brand: brand }
      { authorized: true, created-at: stacks-block-height }
    )
    (ok true)
  )
)

(define-public (mint-fashion-item
  (brand (string-ascii 50))
  (model (string-ascii 100))
  (size (string-ascii 10))
  (color (string-ascii 20))
  (material (string-ascii 100))
  (manufacturing-date uint)
  (owner principal)
)
  (let (
    (item-id (var-get next-item-id))
  )
    (asserts! (validate-brand-input brand) err-invalid-input)
    (asserts! (validate-string-input model) err-invalid-input)
    (asserts! (validate-size-input size) err-invalid-input)
    (asserts! (validate-color-input color) err-invalid-input)
    (asserts! (validate-string-input material) err-invalid-input)
    (asserts! (> manufacturing-date u0) err-invalid-input)
    (asserts! (validate-principal owner) err-invalid-input)
    (asserts! (is-brand-certified brand) err-invalid-brand)
    (map-set fashion-items
      { item-id: item-id }
      {
        brand: brand,
        model: model,
        size: size,
        color: color,
        material: material,
        manufacturing-date: manufacturing-date,
        owner: owner,
        certified: true,
        authenticity-score: u100
      }
    )
    (var-set next-item-id (+ item-id u1))
    (var-set total-certified-items (+ (var-get total-certified-items) u1))
    (ok item-id)
  )
)

(define-public (transfer-ownership (item-id uint) (new-owner principal) (price uint))
  (let (
    (item-data (unwrap! (map-get? fashion-items { item-id: item-id }) err-item-not-found))
    (current-owner (get owner item-data))
  )
    (asserts! (validate-item-id item-id) err-invalid-input)
    (asserts! (is-eq tx-sender current-owner) err-not-owner)
    (asserts! (not (is-eq current-owner new-owner)) err-invalid-input)
    (asserts! (> price u0) err-invalid-input)
    (asserts! (validate-principal new-owner) err-invalid-input)
    (map-set fashion-items
      { item-id: item-id }
      (merge item-data { owner: new-owner })
    )
    (map-set ownership-history
      { item-id: item-id, sequence: u1 }
      {
        from: current-owner,
        to: new-owner,
        timestamp: stacks-block-height,
        price: price
      }
    )
    (ok true)
  )
)

(define-public (verify-authenticity (item-id uint))
  (let (
    (item-data (unwrap! (map-get? fashion-items { item-id: item-id }) err-item-not-found))
  )
    (asserts! (validate-item-id item-id) err-invalid-input)
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (ok (get certified item-data))
  )
)

(define-public (update-authenticity-score (item-id uint) (new-score uint))
  (let (
    (item-data (unwrap! (map-get? fashion-items { item-id: item-id }) err-item-not-found))
  )
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (<= new-score u100) err-invalid-input)
    (map-set fashion-items
      { item-id: item-id }
      (merge item-data { authenticity-score: new-score })
    )
    (ok true)
  )
)