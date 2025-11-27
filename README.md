# Solidity Gas Optimization Stress Test

A multi-file Solidity project designed to challenge the Solidity Prism (/gas) optimization tool with progressively complex inefficiencies across three smart contracts. 
This repository serves as a comprehensive test case for evaluating the depth and accuracy of gas analysis capabilities.

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
  ```
  function fillAll(uint256 value) public {
      for (uint256 i = 0; i < 100; i++) {
          data[i] = value;  // ❌ 100 SSTORE operations
      }
  }
  ```

- **Optimization:** Use a batch function or pre-allocate via constructor/initialization, avoiding repeated storage writes. Alternatively, if data must be set individually, use memory buffer and flush once.

- **Estimated gas savings:** 60-80% reduction per call

### 2. WeightedVoting.sol

**Purpose:** Demonstrates intermediate gas challenges through struct design and redundant storage access patterns.

**Gas Inefficiencies (Medium difficulty to detect):**

- **Problem 1: Non-optimally packed struct**  
  The `Vote` struct is declared as:
  ```
  struct Vote {
      bool yes;           // 1 byte   → slot 0 (wastes 31 bytes)
      uint64 weight;      // 8 bytes  → slot 1 (wastes 24 bytes)
      address voter;      // 20 bytes → slot 2 (wastes 12 bytes)
  }
  ```
  This occupies **3 storage slots** instead of 1. Optimal packing:
  ```
  struct Vote {
      address voter;      // 20 bytes
      uint64 weight;      // 8 bytes
      bool yes;           // 1 byte
      // = 29 bytes → fits in 1 slot
  }
  ```
  **Impact:** Every read/write of a `Vote` struct costs 3x more gas than necessary.

- **Problem 2: Redundant access to `voters` EnumerableSet**  
  The `submitVote()` function checks `voters.contains(msg.sender)` before adding, which performs an extra lookup. The mapping `votes[msg.sender]` already implicitly tracks voters. Dual tracking is wasteful.

- **Problem 3: Inefficient loop in summing**  
  The `sumWithIncentive()` function calls an external contract (`storageDep.sum()`) and performs modulo arithmetic on the result. The external call alone costs 700+ gas (STATICCALL), plus the modulo operation is unnecessary overhead for simple incentive calculation.

- **Estimated gas savings:** 40-50% reduction in vote submission and retrieval operations

### 3. AdvancedProcess.sol

**Purpose:** Combines multiple subtle inefficiencies requiring deeper analysis for optimization.

**Gas Inefficiencies (Hard to detect):**

- **Problem 1: Severe struct packing inefficiency**  
  The `UserInfo` struct is poorly ordered:
  ```
  struct UserInfo {
      uint48 quota;       // 6 bytes  → slot 0 (wastes 26 bytes)
      bool active;        // 1 byte   → slot 1 (wastes 31 bytes)
      uint64 score;       // 8 bytes  → slot 2 (wastes 24 bytes)
  }
  ```
  This uses **3 slots** when optimal packing would use **1 slot**:
  ```
  struct UserInfo {
      uint64 score;       // 8 bytes
      uint48 quota;       // 6 bytes
      bool active;        // 1 byte
      // = 15 bytes → 1 slot
  }
  ```

- **Problem 2: Multiple redundant storage accesses in loop**  
  ```
  function allocateRewards(address[] calldata addrs, uint256 baseReward) public {
      for (uint256 i = 0; i < len; i++) {
          if (users[addrs[i]].active) {                    // SLOAD 1
              users[addrs[i]].score = uint64(
                  users[addrs[i]].score +                   // SLOAD 2 (reload)
                  baseReward + 
                  votingDep.totalVotes()                    // SLOAD from external contract
              );
              rewardPool = rewardPool.add(baseReward);      // SLOAD + SSTORE
          }
      }
  }
  ```
  **Issues:**
  - `users[addrs[i]]` is read 3 times (accessed 3 times in line `if` and line assignment)
  - `rewardPool` is read, computed, and written every loop iteration (could be batched in memory)
  - External call to `votingDep.totalVotes()` in the loop (700+ gas per iteration, should be cached before loop)
  - No use of unchecked arithmetic (modern Solidity 0.8+)

- **Problem 3: Unnecessary SafeMath usage**  
  Solidity ^0.8.0+ has built-in overflow checking. `SafeMath.add()` is redundant overhead:
  ```
  rewardPool = rewardPool.add(baseReward);  // ❌ Extra function call + redundant checks
  ```
  Should be:
  ```
  rewardPool += baseReward;  // ✅ Direct operation, overflow protected by Solidity
  ```

- **Estimated gas savings:** 55-70% reduction per batch operation

## Optimization Strategy & Expected Improvements

| Contract | Issue Type | Current Gas | Optimized Gas | Savings |
|----------|------------|-------------|---------------|---------|
| SimpleStorage | Storage loop | ~200,000 | ~40,000 | **80%** |
| WeightedVoting | Struct packing + redundancy | ~150,000 | ~75,000 | **50%** |
| AdvancedProcess | Multi-slot struct + loop inefficiency + SafeMath | ~300,000 | ~90,000 | **70%** |

## Files Structure

```
contracts/
├── SimpleStorage.sol          (Easy: storage loop anti-pattern)
├── WeightedVoting.sol         (Medium: struct packing + redundancy)
└── AdvancedProcess.sol        (Hard: complex packing + nested inefficiencies)
```

## Dependencies

- **@openzeppelin/contracts** (v5.0.0+)
  - `SafeMath` — arithmetic with overflow protection
  - `EnumerableSet.AddressSet` — gas-efficient enumeration utilities


Generates detailed gas consumption reports per function.

## Analysis Objectives

This project is designed to test your gas optimization tool's ability to:

1. **Detect obvious inefficiencies** (storage loops, redundant logic)
2. **Identify structural sub-optimality** (struct packing, variable ordering)
3. **Find subtle multi-layer issues** (nested access patterns, external call caching)
4. **Suggest precise, actionable improvements** (reordering, memory caching, unchecked blocks)
5. **Estimate realistic gas savings** (before/after comparisons)

## Key Learnings

- **Struct packing matters:** Reordering struct fields can reduce storage slots by 66-75%
- **Loop optimization is critical:** Caching external reads outside loops saves 500+ gas per iteration
- **Redundant checks are expensive:** Eliminate duplicate access patterns and dual-tracking
- **Modern Solidity built-ins:** SafeMath overhead is unnecessary in ^0.8.0+

## References

- [Solidity Gas Optimization Tips](https://soliditylang.org/blog/)
- [OpenZeppelin Gas Optimization Guide](https://docs.openzeppelin.com/contracts/4.x/)
- [EVM Opcode Costs](https://www.evm.codes/)

