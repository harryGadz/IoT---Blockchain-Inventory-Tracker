# 🏭 IoT Blockchain Inventory Tracker

> **Smart contracts that release supplier payments only when production quotas are met** 📊

## 🚀 Overview

The IoT Blockchain Inventory Tracker is a Clarity smart contract that bridges IoT devices with blockchain-based payments. Manufacturing machines update their production data on-chain, and smart contracts automatically release supplier payments only when predetermined quotas are achieved.

## ✨ Key Features

- 🤖 **IoT Integration**: Machines update production data directly on-chain
- 💰 **Automated Payments**: Suppliers get paid only when quotas are met
- 📈 **Real-time Tracking**: Monitor production progress in real-time
- 🔒 **Secure**: Blockchain-based transparency and immutability
- ⚙️ **Flexible Quotas**: Set different quotas for different machines
- 📊 **Production Logs**: Complete audit trail of all production updates

## 🛠️ Contract Functions

### 📝 Registration Functions

#### `register-machine`
Register a new IoT-enabled machine with a production quota.
```clarity
(contract-call? .IoT-Blockchain-Inventory-Tracker register-machine "Machine-A" u1000)
```

#### `register-supplier` 
Register a supplier with payment amount and quota requirements.
```clarity
(contract-call? .IoT-Blockchain-Inventory-Tracker register-supplier "Supplier-Inc" u5000 u800)
```

#### `link-supplier-to-machine`
Link a supplier to a specific machine for quota-based payments.
```clarity
(contract-call? .IoT-Blockchain-Inventory-Tracker link-supplier-to-machine u1 u1)
```

### 🏭 Production Functions

#### `update-production`
Update production count from IoT device (only machine owner can call).
```clarity
(contract-call? .IoT-Blockchain-Inventory-Tracker update-production u1 u50)
```

#### `toggle-machine-status`
Activate/deactivate a machine.
```clarity
(contract-call? .IoT-Blockchain-Inventory-Tracker toggle-machine-status u1)
```

### 💳 Payment Functions

#### `process-supplier-payment`
Release payment to supplier if quota is met (contract owner only).
```clarity
(contract-call? .IoT-Blockchain-Inventory-Tracker process-supplier-payment u1 u1)
```

### 🔍 Read-Only Functions

#### `check-quota-status`
Check if a machine has met its production quota.
```clarity
(contract-call? .IoT-Blockchain-Inventory-Tracker check-quota-status u1)
```

#### `can-process-payment`
Check if a supplier payment can be processed.
```clarity
(contract-call? .IoT-Blockchain-Inventory-Tracker can-process-payment u1 u1)
```

#### `get-machine`
Get complete machine information.
```clarity
(contract-call? .IoT-Blockchain-Inventory-Tracker get-machine u1)
```

## 🎯 Usage Workflow

1. **🏭 Setup Phase**
   - Register machines with production quotas
   - Register suppliers with payment amounts and quota requirements
   - Link suppliers to specific machines

2. **📊 Production Phase** 
   - IoT devices call `update-production` to record output
   - Production data is logged on-chain with timestamps
   - Real-time quota tracking via `check-quota-status`

3. **💰 Payment Phase**
   - Contract owner monitors quota completion
   - When quota is met, `process-supplier-payment` releases funds
   - Automatic STX transfer to supplier address

## 🧪 Testing with Clarinet

```bash
# Check contract syntax
clarinet check

# Run unit tests
npm install
npm test

# Deploy to local devnet
clarinet integrate
```

## 📋 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| `u100` | `ERR-UNAUTHORIZED` | Caller lacks permission |
| `u101` | `ERR-MACHINE-NOT-FOUND` | Machine ID doesn't exist |
| `u102` | `ERR-SUPPLIER-NOT-FOUND` | Supplier ID doesn't exist |
| `u103` | `ERR-INVALID-AMOUNT` | Amount must be greater than 0 |
| `u104` | `ERR-QUOTA-NOT-MET` | Production below required quota |
| `u105` | `ERR-ALREADY-EXISTS` | Resource already exists |
| `u106` | `ERR-MACHINE-INACTIVE` | Machine is not active |
| `u107` | `ERR-INSUFFICIENT-BALANCE` | Not enough STX for payment |

## 🏗️ Architecture

The contract uses three main data structures:

- **Machines Map**: Stores machine info, quotas, and production counts
- **Suppliers Map**: Manages supplier payment details and requirements  
- **Production Logs**: Complete audit trail of all production updates

## 🔧 Requirements

- Clarinet CLI
- Node.js and npm (for testing)
- Stacks blockchain environment

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Add tests for new functionality
4. Run `clarinet check` to ensure no errors
5. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.

---

*Built with ❤️ for the future of IoT and blockchain integration* 🌟
