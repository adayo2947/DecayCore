# DecayCore - Entropy Token (ENT)

A decaying fungible token smart contract for the Stacks blockchain, inspired by Silvio Gesell's demurrage money concept. Balances automatically decay over time, with decayed tokens redirected to a community treasury.

## 🎯 Features

- **Demurrage Mechanism** - Balances decay by a fixed percentage to discourage hoarding
- **Community Treasury** - Decayed tokens automatically sent to treasury
- **Configurable Decay** - Adjustable decay rate and interval
- **Owner-Controlled Minting** - Only contract deployer can mint tokens
- **Automatic Decay Application** - Decay applied before transfers for accurate balances

## 📊 How It Works

The decay mechanism applies a percentage reduction based on block intervals:

```
Decayed Amount = Balance × (Decay Rate / 10000) × Number of Cycles
```

### Default Configuration

| Parameter | Value |
|-----------|-------|
| Decay Rate | 10 basis points (0.10% per cycle) |
| Decay Interval | 100 blocks per cycle |

## 🔧 Contract Functions

### Public Functions

#### `mint(recipient: principal, amount: uint) → Result<bool, ErrorCode>`

Mints new tokens (owner only).

```clarity
(mint 'SP1ABC... u1000)  ;; Mint 1000 tokens to recipient
```

#### `transfer(recipient: principal, amount: uint) → Result<bool, ErrorCode>`

Transfers tokens with automatic decay application.

```clarity
(transfer 'SP2XYZ... u100)  ;; Transfer 100 tokens
```

### Read-Only Functions

#### `get-balance(account: principal) → Result<uint, ErrorCode>`

Returns current account balance.

#### `get-total-supply() → Result<uint, ErrorCode>`

Returns total minted supply.

#### `get-decay-config() → Result<Object, ErrorCode>`

Returns decay configuration (rate, interval, treasury).

## ⚠️ Error Codes

| Code | Name | Description |
|------|------|-------------|
| 400 | ERR-NO-BALANCE | No balance record for account |
| 401 | ERR-INSUFFICIENT-FUNDS | Insufficient balance for transfer |
| 402 | ERR-NOT-AUTHORIZED | Caller not authorized |
| 403 | ERR-INVALID-AMOUNT | Invalid amount |

## 📁 Project Structure

```
DecayCore/
├── contracts/
│   └── DecayCore.clar          # Smart contract
├── tests/
│   └── DecayCore.test.ts       # Test suite
├── settings/
│   ├── Devnet.toml
│   ├── Testnet.toml
│   └── Mainnet.toml
├── Clarinet.toml               # Project config
└── package.json
```

## 🚀 Quick Start

### Prerequisites

- Node.js
- Clarinet SDK
- Vitest

### Installation

```bash
npm install
```

### Verify Contract

```bash
clarinet check
```

### Run Tests

```bash
npm test
```

### Watch Mode

```bash
npm run test:watch
```

### Generate Reports

```bash
npm run test:report
```

## 💡 Example Usage

```clarity
;; Mint 10,000 tokens
(mint 'SP2ABC123... u10000)

;; Transfer 500 tokens (decay applied automatically)
(transfer 'SP3XYZ789... u500)

;; Check balance
(get-balance 'SP2ABC123...)

;; Get decay config
(get-decay-config)
```

## 📝 Notes

- Decay is applied automatically before each transfer
- Decayed tokens are sent directly to the treasury address
- The treasury is set to the contract deployer by default
- Decay calculations use integer arithmetic (basis points)


---

**Made with ❤️ for the Stacks ecosystem**
