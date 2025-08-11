# LendVault Protocol

## Next-Generation Decentralized Lending Infrastructure for Bitcoin

![License](https://img.shields.io/badge/license-ISC-blue.svg)
![Clarity](https://img.shields.io/badge/clarity-v3-orange.svg)
![Stacks](https://img.shields.io/badge/stacks-blockchain-purple.svg)

LendVault revolutionizes Bitcoin-native lending through an innovative smart contract architecture that enables seamless collateralized borrowing with dynamic risk assessment. Built with institutional-grade security and automated liquidation mechanisms, this protocol empowers users to unlock liquidity from their digital assets while maintaining full custody control.

## 🚀 Key Features

- **Dynamic Risk Assessment**: Adaptive interest rates based on loan parameters and market conditions
- **Multi-Token Support**: Flexible collateral management through fungible token standards
- **Automated Liquidation**: Smart liquidation mechanisms to protect protocol solvency
- **Governance-Driven**: Parameter optimization through decentralized governance
- **Institutional Security**: Enterprise-grade security patterns and fail-safes
- **Full Custody Control**: Non-custodial lending preserving user asset ownership

## 🏗️ Architecture Overview

### Core Components

1. **Loan Management System**: Comprehensive loan lifecycle management with state tracking
2. **Collateralization Engine**: Dynamic collateral ratio calculations and monitoring
3. **Interest Rate Oracle**: Adaptive interest rate calculation based on risk factors
4. **Liquidation Engine**: Automated liquidation system for undercollateralized positions
5. **Governance Module**: Administrative functions with multi-signature support

### Smart Contract Structure

```text
contracts/
├── lend-vault.clar      # Main lending protocol contract
└── traits/              # Reusable trait definitions
    └── ft-trait.clar    # Fungible token interface
```

## 📊 Protocol Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Minimum Collateralization Ratio | 150% | Minimum collateral required for loan creation |
| Base Interest Rate | 5% | Annual base interest rate |
| Maximum Loan Term | ~1 year | Maximum loan duration in blocks |
| Liquidation Penalty | 10% (configurable) | Penalty applied during liquidation |

## 🔧 Installation & Setup

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) v2.0+
- [Node.js](https://nodejs.org/) v18+
- [Git](https://git-scm.com/)

### Quick Start

```bash
# Clone the repository
git clone https://github.com/your-org/lend-vault.git
cd lend-vault

# Install dependencies
npm install

# Check contract syntax
clarinet check

# Run tests
npm test

# Run tests with coverage
npm run test:report

# Watch mode for development
npm run test:watch
```

## 📋 Usage Guide

### Creating a Loan

```clarity
;; Create a collateralized loan
(contract-call? .lend-vault create-loan
  .collateral-token     ;; Collateral token contract
  u1000000             ;; Collateral amount (1M microunits)
  u500000              ;; Borrow amount (500K microunits)
)
```

### Repaying a Loan

```clarity
;; Repay loan and release collateral
(contract-call? .lend-vault repay-loan
  u1                   ;; Loan ID
  .collateral-token    ;; Collateral token contract
  .repayment-token     ;; Repayment token contract
  u550000              ;; Repayment amount (including interest)
)
```

### Liquidating an Undercollateralized Loan

```clarity
;; Liquidate a risky loan position
(contract-call? .lend-vault liquidate-loan
  u1                   ;; Loan ID
  'SP1ABC...           ;; Borrower principal
  .collateral-token    ;; Collateral token contract
)
```

## 🔍 Core Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `create-loan` | Create new collateralized loan | `collateral-token`, `collateral-amount`, `borrow-amount` |
| `repay-loan` | Repay loan and release collateral | `loan-id`, `collateral-token`, `repayment-token`, `repayment-amount` |
| `liquidate-loan` | Liquidate undercollateralized loan | `loan-id`, `borrower`, `collateral-token` |
| `set-admin` | Transfer protocol administration | `new-admin` |
| `set-liquidation-penalty` | Update liquidation penalty | `new-penalty` |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-loan-details` | Retrieve loan information | Loan record or none |
| `is-loan-liquidatable` | Check liquidation eligibility | Boolean |
| `calculate-dynamic-interest-rate` | Calculate interest rate for amount | Interest rate (uint) |
| `calculate-current-collateral-ratio` | Calculate current collateral ratio | Ratio percentage (uint) |
| `calculate-total-repayment` | Calculate total repayment including interest | Total amount (uint) |

## 🛡️ Security Features

### Risk Management

- **Minimum Collateralization**: 150% minimum collateral ratio prevents undercollateralization
- **Dynamic Interest Rates**: Risk-adjusted pricing based on loan parameters
- **Automated Liquidation**: Protects protocol from bad debt through timely liquidations
- **Admin Controls**: Governance functions for parameter adjustments

### Error Handling

The protocol implements comprehensive error handling with descriptive error codes:

- `ERR-NOT-AUTHORIZED (1000)`: Unauthorized access attempt
- `ERR-INSUFFICIENT-BALANCE (1001)`: Insufficient token balance
- `ERR-LOAN-NOT-FOUND (1002)`: Invalid loan identifier
- `ERR-INVALID-LOAN-AMOUNT (1003)`: Invalid loan amount parameters
- `ERR-LOAN-ALREADY-LIQUIDATED (1004)`: Loan already liquidated
- `ERR-LOAN-NOT-LIQUIDATABLE (1005)`: Loan not eligible for liquidation
- `ERR-INVALID-COLLATERAL-RATIO (1006)`: Insufficient collateralization

## 🧪 Testing

The protocol includes a comprehensive test suite using Vitest and Clarinet SDK:

```bash
# Run all tests
npm test

# Run tests with detailed coverage report
npm run test:report

# Run tests in watch mode during development
npm run test:watch

# Check contract syntax and types
clarinet check
```

### Test Categories

- **Unit Tests**: Individual function testing
- **Integration Tests**: End-to-end workflow testing
- **Security Tests**: Attack vector and edge case testing
- **Gas Optimization Tests**: Performance and cost analysis

## 🚦 Development Workflow

1. **Contract Development**: Write Clarity contracts in `contracts/`
2. **Testing**: Create comprehensive tests in `tests/`
3. **Validation**: Run `clarinet check` for syntax validation
4. **Testing**: Execute `npm test` for functionality verification
5. **Deployment**: Use Clarinet deployment scripts

## 📈 Roadmap

### Phase 1: Core Protocol ✅

- [x] Basic loan creation and management
- [x] Collateral handling and liquidation
- [x] Interest calculation mechanisms

### Phase 2: Advanced Features 🔄

- [ ] Multi-collateral support
- [ ] Flash loan functionality
- [ ] Governance token integration
- [ ] Advanced liquidation strategies

### Phase 3: Ecosystem Integration 📋

- [ ] DEX integration for automated liquidations
- [ ] Oracle price feeds
- [ ] Cross-chain collateral support
- [ ] Insurance mechanisms

## 🤝 Contributing

We welcome contributions to the LendVault Protocol! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Run the test suite: `npm test`
5. Submit a pull request

## 📄 License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.
