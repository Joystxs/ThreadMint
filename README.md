# ThreadMint 🧵

A decentralized fashion authenticity verification system built on Stacks blockchain using Clarity smart contracts with integrated marketplace functionality.

## Overview

ThreadMint combats fashion counterfeiting by creating immutable digital certificates for authentic fashion items. Each item receives a unique NFT-like token that tracks its authenticity, ownership history, and resale value. The integrated marketplace allows users to buy and sell authenticated items with built-in escrow protection.

## Features

- **Brand Certification**: Register authorized fashion brands
- **Item Authentication**: Mint authenticated fashion items with detailed metadata
- **Ownership Tracking**: Complete ownership history and transfer capabilities
- **Authenticity Verification**: Verify item authenticity with scoring system
- **Resale Value Tracking**: Track item value through ownership transfers
- **Marketplace Integration**: List items for sale with STX payments
- **Escrow System**: Secure buyer-seller transactions with time-limited escrow
- **Purchase Protection**: Automated refunds for expired transactions

## Smart Contract Functions

### Read-Only Functions
- `get-item-details(item-id)` - Get complete item information
- `get-ownership-history(item-id, sequence)` - Get ownership transfer history
- `is-brand-certified(brand)` - Check if brand is certified
- `get-total-certified-items()` - Get total number of certified items
- `is-item-owner(item-id, user)` - Check if user owns specific item
- `get-listing(item-id)` - Get marketplace listing details
- `get-escrow-details(escrow-id)` - Get escrow transaction information
- `is-item-listed(item-id)` - Check if item is currently listed for sale

### Public Functions

#### Authentication Functions
- `register-brand(brand)` - Register a new certified brand (admin only)
- `mint-fashion-item(...)` - Create new authenticated fashion item
- `transfer-ownership(item-id, new-owner, price)` - Transfer item ownership
- `verify-authenticity(item-id)` - Verify item authenticity (admin only)
- `update-authenticity-score(item-id, new-score)` - Update authenticity score

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

;; Mint a fashion item
(contract-call? .threadmint mint-fashion-item 
  "Nike" 
  "Air Max 90" 
  "US-10" 
  "White" 
  "Leather/Mesh" 
  u20240101 
  'SP1234567890)
```

### Marketplace Operations
```clarity
;; List item for sale
(contract-call? .threadmint list-item-for-sale u1 u150000)

;; Create purchase escrow
(contract-call? .threadmint create-purchase-escrow u1)

;; Complete purchase (seller)
(contract-call? .threadmint complete-purchase u1)

;; Cancel expired escrow (buyer)
(contract-call? .threadmint cancel-escrow u1)
```

## Marketplace Features

### Escrow System
- **Secure Transactions**: STX funds are held in escrow until completion
- **Time Protection**: 24-hour expiration window for transactions
- **Automatic Refunds**: Buyers can claim refunds after expiration
- **Seller Confirmation**: Sellers must confirm delivery to release funds

### Listing Management
- **Active Listings**: Items can be listed/delisted by owners
- **Price Setting**: Flexible pricing in STX microunits
- **Ownership Verification**: Only owners can list their items
- **Automatic Cleanup**: Listings removed after successful sales

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

## Testing

Run the test suite:
```bash
clarinet test
```

## Security Features

- **Input Validation**: Comprehensive validation for all parameters
- **Access Control**: Role-based permissions for sensitive operations
- **Escrow Protection**: Time-limited transactions with refund mechanisms
- **Ownership Verification**: Strict ownership checks for all operations

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License

MIT License - see LICENSE file for details