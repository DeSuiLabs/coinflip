# CoinFlip - Sui Blockchain Coin Flip Game

> **A decentralized coin flip gambling smart contract on Sui blockchain. Players bet on binary outcomes with a house-managed pool, configurable fees, partnership discounts, and support for NFT-based partnerships via Kiosk integration.**

A decentralized coin flip gambling game built on the Sui blockchain using Move. Players can place bets on binary outcomes (heads/tails) with a house-managed pool, fee system, and partnership integration.

## Overview

This smart contract implements a coin flip game where:
- Players stake tokens and bet on a boolean outcome (true/false)
- The house manages a pool of funds to cover payouts
- Winners receive 2x their stake minus fees
- A fee system collects revenue for the house
- Partnerships can offer reduced fees to players
- Supports both single and batch (multi-flip) betting

## Features

### Core Gameplay
- **Single Flip**: Place a single bet on heads or tails
- **Multi-Flip**: Place multiple bets in a single transaction with automatic stake splitting
- **Random Generation**: Uses Sui's on-chain random number generator for provably fair outcomes
- **Generic Coin Support**: Works with any SUI coin type

### House Management
- **Pool System**: Separate pools for bet coverage and treasury for collected fees
- **Fee Rate**: Configurable fee percentage (max 10%)
- **Bet Limits**: Minimum and maximum bet amounts per game
- **Admin Controls**: Update fee rates, bet limits, and withdraw funds

### Partnership System
- **Reduced Fees**: Partnerships offer lower fee rates than the default house rate
- **Coin-Based Partnerships**: Simple partnerships for specific coin types
- **NFT-Based Partnerships**: Partnerships requiring Kiosk ownership and NFT verification
- **Dynamic Fee Selection**: System automatically uses the lower fee between house and partnership rates

### Access Control
- **Role-Based Access**: Super admin and treasurer roles for administrative functions
- **Secure Admin Operations**: All sensitive operations require authorized admin capabilities

## Development

### Requirements
- Sui Move compiler
- Sui CLI tools

### Build

```bash
sui move build
```

### Deploy

```bash
sui client publish --gas-budget 100000000
```

## License

See package configuration for license information.