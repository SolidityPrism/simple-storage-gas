# Solidity Gas Optimization Stress Test

A multi-file Solidity project designed to challenge gas optimization tools and auditors with progressively complex inefficiencies across three smart contracts. This repository serves as a comprehensive test case for evaluating the depth and accuracy of gas analysis capabilities.

## Project Overview

This project contains three interacting Solidity contracts that deliberately incorporate gas inefficiencies of varying difficulty levels:

- **SimpleStorage.sol** — Easy gas anti-patterns (storage loops)
- **WeightedVoting.sol** — Intermediate gas issues (struct packing, redundant storage access)
- **AdvancedProcess.sol** — Complex gas optimization challenges (multi-slot struct packing, nested storage reads, SafeMath overhead)

Each contract imports and uses the others, creating realistic cross-contract dependencies while maintaining clear educational value for gas optimization analysis.

## Contracts & Gas Issues

### 1. SimpleStorage.sol

**Purpose:** A simple data storage contract that demonstrates fundamental gas anti-patterns.

**Gas Inefficiencies (Easy to detect):**

- **Problem: Storage writes in loop**  
  The `fillAll(uint256 value)` function writes to a storage array `data[100]` in a tight loop. Each write to storage (SSTORE opcode) costs 20,000 gas (or 5,000 if slot already warm). Writing 100 times can consume 100,000+ gas.
