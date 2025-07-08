# ThreadMint 🧵

A decentralized fashion authenticity verification system built on Stacks blockchain using Clarity smart contracts.

## Overview

ThreadMint combats fashion counterfeiting by creating immutable digital certificates for authentic fashion items. Each item receives a unique NFT-like token that tracks its authenticity, ownership history, and resale value.

## Features

- **Brand Certification**: Register authorized fashion brands
- **Item Authentication**: Mint authenticated fashion items with detailed metadata
- **Ownership Tracking**: Complete ownership history and transfer capabilities
- **Authenticity Verification**: Verify item authenticity with scoring system
- **Resale Value Tracking**: Track item value through ownership transfers

## Smart Contract Functions

### Read-Only Functions
- `get-item-details(item-id)` - Get complete item information
- `get-ownership-history(item-id, sequence)` - Get ownership transfer history
- `is-brand-certified(brand)` - Check if brand is certified
- `get-total-certified-items()` - Get total number of certified items
- `is-item-owner(item-id, user)` - Check if user owns specific item

### Public Functions
- `register-brand(brand)` - Register a new certified brand (admin only)
- `mint-fashion-item(...)` - Create new authenticated fashion item
- `transfer-ownership(item-id, new-owner, price)` - Transfer item ownership
- `verify-authenticity(item-id)` - Verify item authenticity (admin only)
- `update-authenticity-score(item-id, new-score)` - Update authenticity score

## Installation

1. Clone the repository
2. Install Clarinet: `npm install -g @hirosystems/clarinet`
3. Run tests: `clarinet test`
4. Deploy locally: `clarinet console`

## Usage

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

;; Transfer ownership
(contract-call? .threadmint transfer-ownership u1 'SP0987654321 u150000)
```

## Testing

Run the test suite:
```bash
clarinet test
```

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request