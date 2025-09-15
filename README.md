# ThreadMint 🧵

A decentralized fashion authenticity verification system built on Stacks blockchain using Clarity smart contracts with integrated marketplace functionality and multi-signature authentication for high-value items.

## Overview

ThreadMint combats fashion counterfeiting by creating immutable digital certificates for authentic fashion items. Each item receives a unique NFT-like token that tracks its authenticity, ownership history, and resale value. The integrated marketplace allows users to buy and sell authenticated items with built-in escrow protection. For high-value items (≥100,000 STX microunits), the system requires multi-signature verification from multiple brand representatives to ensure maximum authenticity assurance.

## Features

- **Brand Certification**: Register authorized fashion brands with representative management
- **Multi-signature Authentication**: Require multiple brand representatives to verify high-value items
- **Item Authentication**: Mint authenticated fashion items with detailed metadata
- **Ownership Tracking**: Complete ownership history and transfer capabilities
- **Authenticity Verification**: Verify item authenticity with scoring system
- **Resale Value Tracking**: Track item value through ownership transfers
- **Marketplace Integration**: List items for sale with STX payments and enhanced security for high-value items
- **Escrow System**: Secure buyer-seller transactions with time-limited escrow
- **Purchase Protection**: Automated refunds for expired transactions
- **Representative Management**: Add/remove brand representatives for multi-sig operations

## Multi-signature Authentication

### High-Value Item Protection
Items with estimated values ≥100,000 STX microunits require multi-signature verification:
- **Automatic Detection**: System automatically flags high-value items during minting
- **Verification Process**: Requires signatures from 2+ brand representatives
- **Time-Limited**: Verification requests expire after ~7 days
- **Enhanced Security**: High-value marketplace listings require authenticity score ≥90

### Multi-signature Workflow
1. **Mint High-Value Item**: Item created with `requires-multisig: true`, `certified: false`
2. **Create Verification**: Brand representative initiates verification request
3. **Collect Signatures**: Multiple representatives sign the verification
4. **Auto-Complete**: Item automatically certified when sufficient signatures collected

## Smart Contract Functions

### Read-Only Functions
- `get-item-details(item-id)` - Get complete item information including multi-sig status
- `get-ownership-history(item-id, sequence)` - Get ownership transfer history
- `is-brand-certified(brand)` - Check if brand is certified
- `get-total-certified-items()` - Get total number of certified items
- `is-item-owner(item-id, user)` - Check if user owns specific item
- `get-listing(item-id)` - Get marketplace listing details
- `get-escrow-details(escrow-id)` - Get escrow transaction information
- `is-item-listed(item-id)` - Check if item is currently listed for sale
- `get-verification-details(verification-id)` - Get multi-sig verification details
- `get-brand-representative(brand, representative)` - Check representative authorization
- `has-signed-verification(verification-id, signer)` - Check if user has signed verification
- `get-high-value-threshold()` - Get current high-value threshold (100,000 STX microunits)
- `get-required-signatures()` - Get required signatures count (2)

### Public Functions

#### Authentication Functions
- `register-brand(brand)` - Register a new certified brand (admin only)
- `add-brand-representative(brand, representative)` - Add brand representative (admin only)
- `remove-brand-representative(brand, representative)` - Remove brand representative (admin only)
- `mint-fashion-item(brand, model, size, color, material, manufacturing-date, owner, estimated-value)` - Create new authenticated fashion item
- `transfer-ownership(item-id, new-owner, price)` - Transfer item ownership
- `verify-authenticity(item-id)` - Verify item authenticity (admin only)
- `update-authenticity-score(item-id, new-score)` - Update authenticity score

#### Multi-signature Functions
- `create-multisig-verification(item-id)` - Create verification request for high-value item
- `sign-verification(verification-id)` - Sign verification request as brand representative

#### Marketplace Functions
- `list-item-for-sale(item-id, price)` - List authenticated item for sale
- `remove-listing(item-id)` - Remove item from marketplace
- `create-purchase-escrow(item-id)` - Create escrow transaction for purchase
- `complete-purchase(escrow-id)` - Complete purchase and transfer ownership
- `cancel-escrow(escrow-id)` - Cancel expired escrow and refund buyer

## Installation

1. Clone the repository
2. Install Clarinet: `npm install -g @hirosystems/clarinet`
3. Run tests: `clarinet test`
4. Deploy locally: `clarinet console`

## Usage

### Basic Authentication
```clarity
;; Register a brand (admin only)
(contract-call? .threadmint register-brand "Nike")

;; Add brand representatives (admin only)
(contract-call? .threadmint add-brand-representative "Nike" 'SP1234567890ABCDEF)
(contract-call? .threadmint add-brand-representative "Nike" 'SP0987654321FEDCBA)

;; Mint a regular fashion item
(contract-call? .threadmint mint-fashion-item 
  "Nike" 
  "Air Max 90" 
  "US-10" 
  "White" 
  "Leather/Mesh" 
  u20240101 
  'SP1234567890
  u50000) ;; Below threshold - auto-certified

;; Mint a high-value fashion item
(contract-call? .threadmint mint-fashion-item 
  "Nike" 
  "Air Jordan 1 Retro High OG" 
  "US-10" 
  "Chicago" 
  "Premium Leather" 
  u20240101 
  'SP1234567890
  u150000) ;; Above threshold - requires multi-sig
```

### Multi-signature Verification
```clarity
;; Create verification request (brand representative)
(contract-call? .threadmint create-multisig-verification u2)

;; Sign verification (first representative)
(contract-call? .threadmint sign-verification u1)

;; Sign verification (second representative) - auto-completes certification
(contract-call? .threadmint sign-verification u1)
```

### Marketplace Operations
```clarity
;; List regular item for sale
(contract-call? .threadmint list-item-for-sale u1 u75000)

;; List high-value item for sale (requires authenticity score ≥90)
(contract-call? .threadmint list-item-for-sale u2 u200000)

;; Create purchase escrow
(contract-call? .threadmint create-purchase-escrow u1)

;; Complete purchase (seller)
(contract-call? .threadmint complete-purchase u1)

;; Cancel expired escrow (buyer)
(contract-call? .threadmint cancel-escrow u1)
```

## Multi-signature Security Features

### High-Value Item Protection
- **Automatic Detection**: Items with estimated value ≥100,000 STX microunits automatically flagged
- **Dual Verification**: Requires minimum 2 brand representative signatures
- **Time-Limited Process**: Verification requests expire after ~7 days (1008 blocks)
- **Enhanced Marketplace Security**: High-value listings require authenticity score ≥90

### Representative Management
- **Authorized Representatives**: Only admin can add/remove brand representatives
- **Brand-Specific**: Representatives are authorized per brand
- **Signature Tracking**: System tracks who signed each verification
- **Duplicate Prevention**: Representatives cannot sign the same verification twice

### Verification Process
- **Request Creation**: Any brand representative can create verification request
- **Collaborative Signing**: Multiple representatives must sign
- **Automatic Completion**: Item certified when required signatures reached
- **Audit Trail**: Complete signature history maintained

## Error Codes

- `u100` - Not authorized
- `u101` - Item not found
- `u102` - Already certified
- `u103` - Not owner
- `u104` - Invalid brand
- `u105` - Invalid input
- `u106` - Listing not found
- `u107` - Item not for sale
- `u108` - Insufficient payment
- `u109` - Cannot buy own item
- `u110` - Escrow not found
- `u111` - Escrow expired
- `u112` - Escrow not expired
- `u113` - Already listed
- `u114` - Multi-signature required
- `u115` - Already signed
- `u116` - Insufficient signatures
- `u117` - Not brand representative
- `u118` - Multi-sig verification not found
- `u119` - Multi-sig already completed

## Testing

Run the test suite:
```bash
clarinet test
```

## Security Features

- **Input Validation**: Comprehensive validation for all parameters
- **Access Control**: Role-based permissions for sensitive operations
- **Multi-signature Authentication**: Enhanced verification for high-value items
- **Escrow Protection**: Time-limited transactions with refund mechanisms
- **Ownership Verification**: Strict ownership checks for all operations
- **Representative Authorization**: Secure brand representative management
- **Signature Verification**: Prevention of duplicate signatures and unauthorized access

## Architecture

### Multi-signature Components
- **Brand Representatives Map**: Stores authorized representatives per brand
- **Verification Requests Map**: Tracks active verification requests
- **Signature Tracking Map**: Records individual signatures
- **Automatic Certification**: Items certified when threshold reached

### Security Considerations
- **High-Value Threshold**: Configurable threshold for multi-sig requirement
- **Time Limits**: Verification requests have expiration dates
- **Representative Validation**: Only authorized representatives can participate
- **Audit Trail**: Complete history of verification process

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request
