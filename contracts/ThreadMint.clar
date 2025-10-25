;; ThreadMint - Fashion Authentication System with Marketplace and Multi-signature Authentication
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
(define-constant err-multisig-required (err u114))
(define-constant err-already-signed (err u115))
(define-constant err-insufficient-signatures (err u116))
(define-constant err-not-brand-representative (err u117))
(define-constant err-multisig-not-found (err u118))
(define-constant err-multisig-already-completed (err u119))

;; Multi-signature constants
(define-constant high-value-threshold u100000) ;; STX microunits threshold for requiring multi-sig
(define-constant required-signatures u2) ;; Number of signatures required

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
    authenticity-score: uint,
    requires-multisig: bool,
    certified-at: (optional uint),
    created-at: uint
  }
)

;; Brand item index for efficient querying
(define-map brand-item-index
  { brand: (string-ascii 50), item-id: uint }
  { exists: bool }
)

;; Certified brands with representatives
(define-map certified-brands
  { brand: (string-ascii 50) }
  { authorized: bool, created-at: uint }
)

;; Brand representatives for multi-signature verification
(define-map brand-representatives
  { brand: (string-ascii 50), representative: principal }
  { authorized: bool, added-at: uint }
)

;; Multi-signature verification requests
(define-map multisig-verifications
  { verification-id: uint }
  {
    item-id: uint,
    brand: (string-ascii 50),
    created-by: principal,
    created-at: uint,
    signatures-count: uint,
    completed: bool,
    expires-at: uint
  }
)

;; Track signatures for each verification
(define-map verification-signatures
  { verification-id: uint, signer: principal }
  { signed-at: uint }
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
(define-data-var next-verification-id uint u1)
(define-data-var escrow-duration uint u144) ;; ~24 hours in blocks
(define-data-var verification-duration uint u1008) ;; ~7 days in blocks

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

(define-private (validate-verification-id (verification-id uint))
  (and (> verification-id u0) (< verification-id (var-get next-verification-id)))
)

(define-private (is-high-value-item (price uint))
  (>= price high-value-threshold)
)

(define-private (is-brand-representative (brand (string-ascii 50)) (user principal))
  (default-to false 
    (get authorized 
      (map-get? brand-representatives { brand: brand, representative: user })
    )
  )
)

(define-private (has-already-signed (verification-id uint) (signer principal))
  (is-some (map-get? verification-signatures { verification-id: verification-id, signer: signer }))
)

;; Read-only functions with enhanced validation
(define-read-only (get-item-details (item-id uint))
  (if (validate-item-id item-id)
    (map-get? fashion-items { item-id: item-id })
    none
  )
)

(define-read-only (get-ownership-history (item-id uint) (sequence uint))
  (if (and (validate-item-id item-id) (validate-sequence sequence))
    (map-get? ownership-history { item-id: item-id, sequence: sequence })
    none
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

(define-read-only (get-verification-details (verification-id uint))
  (if (validate-verification-id verification-id)
    (map-get? multisig-verifications { verification-id: verification-id })
    none
  )
)

(define-read-only (get-brand-representative (brand (string-ascii 50)) (representative principal))
  (if (validate-brand-input brand)
    (map-get? brand-representatives { brand: brand, representative: representative })
    none
  )
)

(define-read-only (has-signed-verification (verification-id uint) (signer principal))
  (if (validate-verification-id verification-id)
    (is-some (map-get? verification-signatures { verification-id: verification-id, signer: signer }))
    false
  )
)

(define-read-only (get-high-value-threshold)
  high-value-threshold
)

(define-read-only (get-required-signatures)
  required-signatures
)

(define-read-only (is-brand-item (brand (string-ascii 50)) (item-id uint))
  (if (and (validate-brand-input brand) (validate-item-id item-id))
    (default-to false (get exists (map-get? brand-item-index { brand: brand, item-id: item-id })))
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

(define-public (add-brand-representative (brand (string-ascii 50)) (representative principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (validate-brand-input brand) err-invalid-input)
    (asserts! (validate-principal representative) err-invalid-input)
    (asserts! (is-brand-certified brand) err-invalid-brand)
    
    (map-set brand-representatives
      { brand: brand, representative: representative }
      { authorized: true, added-at: stacks-block-height }
    )
    (ok true)
  )
)

(define-public (remove-brand-representative (brand (string-ascii 50)) (representative principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (validate-brand-input brand) err-invalid-input)
    (asserts! (validate-principal representative) err-invalid-input)
    
    (map-delete brand-representatives { brand: brand, representative: representative })
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
  (estimated-value uint)
)
  (let (
    (item-id (var-get next-item-id))
    (requires-multisig (is-high-value-item estimated-value))
    (current-block stacks-block-height)
  )
    ;; Validate all inputs first
    (asserts! (validate-brand-input brand) err-invalid-input)
    (asserts! (validate-string-input model) err-invalid-input)
    (asserts! (validate-size-input size) err-invalid-input)
    (asserts! (validate-color-input color) err-invalid-input)
    (asserts! (validate-string-input material) err-invalid-input)
    (asserts! (> manufacturing-date u0) err-invalid-input)
    (asserts! (validate-principal owner) err-invalid-input)
    (asserts! (validate-amount estimated-value) err-invalid-input)
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
        certified: (not requires-multisig),
        authenticity-score: (if requires-multisig u0 u100),
        requires-multisig: requires-multisig,
        certified-at: (if requires-multisig none (some current-block)),
        created-at: current-block
      }
    )
    
    ;; Add to brand index
    (map-set brand-item-index
      { brand: brand, item-id: item-id }
      { exists: true }
    )
    
    (var-set next-item-id (+ item-id u1))
    
    ;; Only increment certified items if not requiring multi-sig
    (if (not requires-multisig)
      (var-set total-certified-items (+ (var-get total-certified-items) u1))
      true
    )
    (ok item-id)
  )
)

(define-public (create-multisig-verification (item-id uint))
  (begin
    ;; Validate inputs first
    (asserts! (validate-item-id item-id) err-invalid-input)
    
    (let (
      (item-data (unwrap! (map-get? fashion-items { item-id: item-id }) err-item-not-found))
      (brand (get brand item-data))
      (verification-id (var-get next-verification-id))
      (current-block stacks-block-height)
    )
      (asserts! (get requires-multisig item-data) err-invalid-input)
      (asserts! (not (get certified item-data)) err-already-certified)
      (asserts! (is-brand-representative brand tx-sender) err-not-brand-representative)
      
      (map-set multisig-verifications
        { verification-id: verification-id }
        {
          item-id: item-id,
          brand: brand,
          created-by: tx-sender,
          created-at: current-block,
          signatures-count: u0,
          completed: false,
          expires-at: (+ current-block (var-get verification-duration))
        }
      )
      
      (var-set next-verification-id (+ verification-id u1))
      (ok verification-id)
    )
  )
)

(define-public (sign-verification (verification-id uint))
  (begin
    ;; Validate inputs first
    (asserts! (validate-verification-id verification-id) err-invalid-input)
    
    (let (
      (verification-data (unwrap! (map-get? multisig-verifications { verification-id: verification-id }) err-multisig-not-found))
      (brand (get brand verification-data))
      (current-block stacks-block-height)
      (expires-at (get expires-at verification-data))
      (current-signatures (get signatures-count verification-data))
    )
      (asserts! (not (get completed verification-data)) err-multisig-already-completed)
      (asserts! (<= current-block expires-at) err-escrow-expired)
      (asserts! (is-brand-representative brand tx-sender) err-not-brand-representative)
      (asserts! (not (has-already-signed verification-id tx-sender)) err-already-signed)
      
      ;; Add signature
      (map-set verification-signatures
        { verification-id: verification-id, signer: tx-sender }
        { signed-at: current-block }
      )
      
      (let (
        (new-signatures-count (+ current-signatures u1))
      )
        ;; Update signatures count
        (map-set multisig-verifications
          { verification-id: verification-id }
          (merge verification-data { signatures-count: new-signatures-count })
        )
        
        ;; Check if we have enough signatures to complete verification
        (if (>= new-signatures-count required-signatures)
          (try! (complete-multisig-verification verification-id))
          true
        )
      )
      
      (ok true)
    )
  )
)

(define-private (complete-multisig-verification (verification-id uint))
  (let (
    (verification-data (unwrap! (map-get? multisig-verifications { verification-id: verification-id }) err-multisig-not-found))
    (item-id (get item-id verification-data))
    (item-data (unwrap! (map-get? fashion-items { item-id: item-id }) err-item-not-found))
    (current-block stacks-block-height)
  )
    ;; Mark verification as completed
    (map-set multisig-verifications
      { verification-id: verification-id }
      (merge verification-data { completed: true })
    )
    
    ;; Certify the item with timestamp
    (map-set fashion-items
      { item-id: item-id }
      (merge item-data { 
        certified: true, 
        authenticity-score: u100,
        certified-at: (some current-block)
      })
    )
    
    ;; Increment certified items counter
    (var-set total-certified-items (+ (var-get total-certified-items) u1))
    
    (ok true)
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
      (asserts! (get certified item-data) err-not-authorized)
      
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
      (asserts! (get certified item-data) err-not-authorized)
      (asserts! (not (is-item-listed item-id)) err-already-listed)
      
      ;; Check if high-value item requires multi-sig for marketplace listing
      (if (is-high-value-item price)
        (asserts! (>= (get authenticity-score item-data) u90) err-insufficient-signatures)
        true
      )
      
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
      (asserts! (get certified item-data) err-not-authorized)
      
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