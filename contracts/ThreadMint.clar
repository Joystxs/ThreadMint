;; ThreadMint - Fashion Authentication System with Marketplace
;; This contract manages fashion item authentication, ownership tracking, and marketplace transactions

(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-item-not-found (err u101))
(define-constant err-already-certified (err u102))
(define-constant err-not-owner (err u103))
(define-constant err-invalid-brand (err u104))
(define-constant err-invalid-input (err u105))
(define-constant err-listing-not-found (err u106))
(define-constant err-item-not-for-sale (err u107))
(define-constant err-insufficient-payment (err u108))
(define-constant err-cannot-buy-own-item (err u109))
(define-constant err-escrow-not-found (err u110))
(define-constant err-escrow-expired (err u111))
(define-constant err-escrow-not-expired (err u112))
(define-constant err-already-listed (err u113))

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

;; Marketplace listings
(define-map marketplace-listings
  { item-id: uint }
  {
    seller: principal,
    price: uint,
    listed-at: uint,
    active: bool
  }
)

;; Escrow system
(define-map escrow-transactions
  { escrow-id: uint }
  {
    item-id: uint,
    buyer: principal,
    seller: principal,
    amount: uint,
    created-at: uint,
    expires-at: uint,
    status: (string-ascii 20)
  }
)

;; Data variables
(define-data-var next-item-id uint u1)
(define-data-var total-certified-items uint u0)
(define-data-var next-escrow-id uint u1)
(define-data-var escrow-duration uint u144) ;; ~24 hours in blocks

;; Enhanced validation functions
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

(define-private (validate-sequence (sequence uint))
  (>= sequence u1)
)

(define-private (validate-score (score uint))
  (<= score u100)
)

(define-private (validate-amount (amount uint))
  (> amount u0)
)

(define-private (validate-escrow-id (escrow-id uint))
  (and (> escrow-id u0) (< escrow-id (var-get next-escrow-id)))
)

;; Read-only functions with enhanced validation
(define-read-only (get-item-details (item-id uint))
  (begin
    (if (validate-item-id item-id)
      (map-get? fashion-items { item-id: item-id })
      none
    )
  )
)

(define-read-only (get-ownership-history (item-id uint) (sequence uint))
  (begin
    (if (and (validate-item-id item-id) (validate-sequence sequence))
      (map-get? ownership-history { item-id: item-id, sequence: sequence })
      none
    )
  )
)

(define-read-only (is-brand-certified (brand (string-ascii 50)))
  (if (validate-brand-input brand)
    (default-to false (get authorized (map-get? certified-brands { brand: brand })))
    false
  )
)

(define-read-only (get-total-certified-items)
  (var-get total-certified-items)
)

(define-read-only (get-next-item-id)
  (var-get next-item-id)
)

(define-read-only (is-item-owner (item-id uint) (user principal))
  (if (validate-item-id item-id)
    (match (map-get? fashion-items { item-id: item-id })
      item-data (is-eq (get owner item-data) user)
      false
    )
    false
  )
)

(define-read-only (get-listing (item-id uint))
  (if (validate-item-id item-id)
    (map-get? marketplace-listings { item-id: item-id })
    none
  )
)

(define-read-only (get-escrow-details (escrow-id uint))
  (if (validate-escrow-id escrow-id)
    (map-get? escrow-transactions { escrow-id: escrow-id })
    none
  )
)

(define-read-only (is-item-listed (item-id uint))
  (match (get-listing item-id)
    listing-data (get active listing-data)
    false
  )
)

;; Public functions with improved validation order
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
    ;; Validate all inputs first
    (asserts! (validate-brand-input brand) err-invalid-input)
    (asserts! (validate-string-input model) err-invalid-input)
    (asserts! (validate-size-input size) err-invalid-input)
    (asserts! (validate-color-input color) err-invalid-input)
    (asserts! (validate-string-input material) err-invalid-input)
    (asserts! (> manufacturing-date u0) err-invalid-input)
    (asserts! (validate-principal owner) err-invalid-input)
    (asserts! (is-brand-certified brand) err-invalid-brand)
    
    ;; All validations passed, now mint the item
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
  (begin
    ;; Validate inputs first
    (asserts! (validate-item-id item-id) err-invalid-input)
    (asserts! (validate-principal new-owner) err-invalid-input)
    (asserts! (> price u0) err-invalid-input)
    
    (let (
      (item-data (unwrap! (map-get? fashion-items { item-id: item-id }) err-item-not-found))
      (current-owner (get owner item-data))
    )
      (asserts! (is-eq tx-sender current-owner) err-not-owner)
      (asserts! (not (is-eq current-owner new-owner)) err-invalid-input)
      
      ;; Remove from marketplace if listed
      (map-delete marketplace-listings { item-id: item-id })
      
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
)

(define-public (verify-authenticity (item-id uint))
  (begin
    ;; Validate inputs first, then check authorization
    (asserts! (validate-item-id item-id) err-invalid-input)
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    
    (let (
      (item-data (unwrap! (map-get? fashion-items { item-id: item-id }) err-item-not-found))
    )
      (ok (get certified item-data))
    )
  )
)

(define-public (update-authenticity-score (item-id uint) (new-score uint))
  (begin
    ;; Validate inputs first
    (asserts! (validate-item-id item-id) err-invalid-input)
    (asserts! (validate-score new-score) err-invalid-input)
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    
    (let (
      (item-data (unwrap! (map-get? fashion-items { item-id: item-id }) err-item-not-found))
    )
      (map-set fashion-items
        { item-id: item-id }
        (merge item-data { authenticity-score: new-score })
      )
      (ok true)
    )
  )
)

;; Marketplace functions
(define-public (list-item-for-sale (item-id uint) (price uint))
  (begin
    ;; Validate inputs first
    (asserts! (validate-item-id item-id) err-invalid-input)
    (asserts! (validate-amount price) err-invalid-input)
    
    (let (
      (item-data (unwrap! (map-get? fashion-items { item-id: item-id }) err-item-not-found))
      (current-owner (get owner item-data))
    )
      (asserts! (is-eq tx-sender current-owner) err-not-owner)
      (asserts! (not (is-item-listed item-id)) err-already-listed)
      
      (map-set marketplace-listings
        { item-id: item-id }
        {
          seller: current-owner,
          price: price,
          listed-at: stacks-block-height,
          active: true
        }
      )
      (ok true)
    )
  )
)

(define-public (remove-listing (item-id uint))
  (begin
    ;; Validate inputs first
    (asserts! (validate-item-id item-id) err-invalid-input)
    
    (let (
      (listing-data (unwrap! (map-get? marketplace-listings { item-id: item-id }) err-listing-not-found))
      (seller (get seller listing-data))
    )
      (asserts! (is-eq tx-sender seller) err-not-owner)
      (asserts! (get active listing-data) err-item-not-for-sale)
      
      (map-set marketplace-listings
        { item-id: item-id }
        (merge listing-data { active: false })
      )
      (ok true)
    )
  )
)

(define-public (create-purchase-escrow (item-id uint))
  (begin
    ;; Validate inputs first
    (asserts! (validate-item-id item-id) err-invalid-input)
    
    (let (
      (listing-data (unwrap! (map-get? marketplace-listings { item-id: item-id }) err-listing-not-found))
      (item-data (unwrap! (map-get? fashion-items { item-id: item-id }) err-item-not-found))
      (seller (get seller listing-data))
      (price (get price listing-data))
      (escrow-id (var-get next-escrow-id))
      (current-block stacks-block-height)
    )
      (asserts! (get active listing-data) err-item-not-for-sale)
      (asserts! (not (is-eq tx-sender seller)) err-cannot-buy-own-item)
      
      ;; Transfer STX to contract for escrow
      (try! (stx-transfer? price tx-sender (as-contract tx-sender)))
      
      (map-set escrow-transactions
        { escrow-id: escrow-id }
        {
          item-id: item-id,
          buyer: tx-sender,
          seller: seller,
          amount: price,
          created-at: current-block,
          expires-at: (+ current-block (var-get escrow-duration)),
          status: "active"
        }
      )
      
      (var-set next-escrow-id (+ escrow-id u1))
      (ok escrow-id)
    )
  )
)

(define-public (complete-purchase (escrow-id uint))
  (begin
    ;; Validate inputs first
    (asserts! (validate-escrow-id escrow-id) err-invalid-input)
    
    (let (
      (escrow-data (unwrap! (map-get? escrow-transactions { escrow-id: escrow-id }) err-escrow-not-found))
      (item-id (get item-id escrow-data))
      (buyer (get buyer escrow-data))
      (seller (get seller escrow-data))
      (amount (get amount escrow-data))
      (expires-at (get expires-at escrow-data))
      (item-data (unwrap! (map-get? fashion-items { item-id: item-id }) err-item-not-found))
    )
      (asserts! (is-eq tx-sender seller) err-not-authorized)
      (asserts! (is-eq (get status escrow-data) "active") err-invalid-input)
      (asserts! (<= stacks-block-height expires-at) err-escrow-expired)
      
      ;; Transfer STX to seller
      (try! (as-contract (stx-transfer? amount tx-sender seller)))
      
      ;; Transfer item ownership
      (map-set fashion-items
        { item-id: item-id }
        (merge item-data { owner: buyer })
      )
      
      ;; Update ownership history
      (map-set ownership-history
        { item-id: item-id, sequence: u1 }
        {
          from: seller,
          to: buyer,
          timestamp: stacks-block-height,
          price: amount
        }
      )
      
      ;; Remove marketplace listing
      (map-delete marketplace-listings { item-id: item-id })
      
      ;; Mark escrow as completed
      (map-set escrow-transactions
        { escrow-id: escrow-id }
        (merge escrow-data { status: "completed" })
      )
      
      (ok true)
    )
  )
)

(define-public (cancel-escrow (escrow-id uint))
  (begin
    ;; Validate inputs first
    (asserts! (validate-escrow-id escrow-id) err-invalid-input)
    
    (let (
      (escrow-data (unwrap! (map-get? escrow-transactions { escrow-id: escrow-id }) err-escrow-not-found))
      (buyer (get buyer escrow-data))
      (amount (get amount escrow-data))
      (expires-at (get expires-at escrow-data))
    )
      (asserts! (is-eq tx-sender buyer) err-not-authorized)
      (asserts! (is-eq (get status escrow-data) "active") err-invalid-input)
      (asserts! (> stacks-block-height expires-at) err-escrow-not-expired)
      
      ;; Refund STX to buyer
      (try! (as-contract (stx-transfer? amount tx-sender buyer)))
      
      ;; Mark escrow as cancelled
      (map-set escrow-transactions
        { escrow-id: escrow-id }
        (merge escrow-data { status: "cancelled" })
      )
      
      (ok true)
    )
  )
)