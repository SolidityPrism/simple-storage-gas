edit
# Solidity Gas Optimization Stress Test

A multi-file Solidity project designed to challenge the Solidity Prism (/gas) optimization tool with progressively complex inefficiencies across three smart contracts. 
This repository serves as a comprehensive test case for evaluating the depth and accuracy of gas analysis capabilities.

## Project Overview

This project contains five interacting Solidity contracts that deliberately incorporate gas inefficiencies of varying difficulty levels:

- **ExternalCallInLoop.sol** — Easy gas anti-patterns (external calls in loops)
- **UnnecessarySafeMath.sol** — Easy gas issues (SafeMath in Solidity 0.8+)
- **SimpleStorage.sol** — Intermediate gas issues (storage loops, events in loops)
- **WeightedVoting.sol** — Advanced gas challenges (struct packing, redundant storage access)
- **AdvancedProcess.sol** — Complex gas optimization challenges (multi-slot struct packing, nested storage reads, SafeMath overhead)

Each contract incorporates realistic patterns while maintaining clear educational value for gas optimization analysis.

## Contracts & Gas Issues

### 1. ExternalCallInLoop.sol

**Purpose:** Demonstrates fundamental gas anti-patterns with external calls.

**Gas Inefficiencies (Easy to detect):**

- **Problem: External calls in loops**  
  Multiple functions perform external calls inside loops, which is extremely gas-inefficient:
  ```
  function distributeToMany(uint256[] calldata amounts) external {
      for (uint i = 0; i < recipients.length; i++) {
          token.transfer(recipients[i], amounts[i]); // ❌ EXTERNAL CALL IN LOOP
      }
  }
  ```

- **Problem: Inefficient array initialization**  
  Using `push()` in loops instead of batch operations:
  ```
  function addRecipients(address[] calldata newRecipients) external {
      for (uint i = 0; i < newRecipients.length; i++) {
          recipients.push(newRecipients[i]); // ❌ PUSH IN LOOP
      }
  }
  ```

- **Optimization:** Cache external call results and use batch operations
- **Estimated gas savings:** 60-80% reduction per call

### 2. UnnecessarySafeMath.sol

**Purpose:** Demonstrates outdated SafeMath usage in modern Solidity.

**Gas Inefficiencies (Easy to detect):**

- **Problem: SafeMath in Solidity 0.8+**  
  Using SafeMath library functions when Solidity has built-in overflow checking:
  ```
  function increment() external {
      counter = counter.add(1); // ❌ SAFEMATH .add() UNNECESSARY
  }
  ```

- **Problem: Repeated storage access**  
  Multiple writes to the same storage variable in sequence:
  ```
  function doubleIncrement() external {
      counter = counter.add(1); // ❌ 1st storage access
      counter = counter.add(1); // ❌ 2nd storage access (wasteful)
  }
  ```

- **Problem: Redundant condition checks**  
  Similar conditions checked multiple times:
  ```
  if (x > 0) {
      // ...
  }
  if (x != 0) { // ❌ REDUNDANT CHECK
      // ...
  }
  ```

- **Estimated gas savings:** 30-50% reduction per operation

### 3. SimpleStorage.sol

**Purpose:** A simple data storage contract that demonstrates intermediate gas anti-patterns.

**Gas Inefficiencies (Medium difficulty to detect):**

- **Problem: Storage writes in loop**  
  The `fillAll(uint256 value)` function writes to a storage array `data[100]` in a tight loop. Each write to storage (SSTORE opcode) costs 20,000 gas (or 5,000 if slot already warm). Writing 100 times can consume 100,000+ gas.
  ```
  function fillAll(uint256 value) public {
      for (uint256 i = 0; i < 100; i++) {
          data[i] = value;  // ❌ 100 SSTORE operations
      }
  }
  ```

- **Problem: Events in loops**  
  Emitting events inside loops instead of batching:
  ```
  function setMultipleValues(uint256[] calldata indices, uint256[] calldata values) external {
      for (uint i = 0; i < indices.length; i++) {
          data[indices[i]] = values[i];
          emit ValueSet(indices[i], values[i]); // ❌ EVENT IN LOOP
      }
  }
  ```

- **Problem: Redundant calculations**  
  Performing the same expensive operation multiple times:
  ```
  function calculateStats() external {
      uint256 s1 = sum();  // ❌ External call + loop
      uint256 s2 = sum();  // ❌ Same calculation repeated!
      total = s1 + s2;
  }
  ```

- **Optimization:** Use batch operations, cache results, and optimize loop conditions
- **Estimated gas savings:** 60-80% reduction per call

### 4. WeightedVoting.sol

**Purpose:** Demonstrates advanced gas challenges through poor struct design and redundant storage access patterns.

**Gas Inefficiencies (Advanced difficulty to detect):**

- **Problem 1: Severely non-optimally packed structs**  
  The `Vote` struct uses **5 storage slots** instead of 2:
  ```
  struct Vote {
      bool yes;           // 1 byte   → slot 0 (wastes 31 bytes)
      uint256 proposalId; // 32 bytes → slot 1 (forces new slot)
      uint64 weight;      // 8 bytes  → slot 2 (can't go back to slot 0)
      address voter;      // 20 bytes → slot 3 (can't fit in slot 2)
      bool executed;      // 1 byte   → slot 4 (should be with other bools!)
      // Total: 5 slots but could use 2!
  }
  ```
  **Optimal packing:**
  ```
  struct Vote {
      uint256 proposalId; // 32 bytes → slot 0
      address voter;      // 20 bytes → slot 1
      uint64 weight;      // 8 bytes  → slot 1
      bool yes;           // 1 byte   → slot 1  
      bool executed;      // 1 byte   → slot 1
      // = 62 bytes → 2 slots total
  }
  ```

- **Problem 2: Another poorly packed struct**  
  The `Proposal` struct uses **4 slots** instead of 2:
  ```
  struct Proposal {
      bool active;        // 1 byte   → slot 0 (wastes 31 bytes)
      uint128 minVotes;   // 16 bytes → slot 1 (wastes 16 bytes)
      uint128 maxVotes;   // 16 bytes → slot 2 (should be in slot 1!)
      bool finalized;     // 1 byte   → slot 3 (should be in slot 0!)
      // Total: 4 slots but could use 2!
  }
  ```

- **Problem 3: Inefficient struct creation**  
  Creating struct in memory then copying to storage:
  ```
  Vote memory newVote = Vote(yes, currentProposalId, weight, msg.sender, false);
  votes[msg.sender] = newVote; // ❌ INEFFICIENT STRUCT COPY
  ```

- **Problem 4: External calls in loops**  
  Performing external calls inside iteration loops:
  ```
  uint256 currentSum = storageDep.sum(); // ❌ EXTERNAL CALL IN LOOP
  ```

- **Estimated gas savings:** 60-70% reduction in vote operations

### 5. AdvancedProcess.sol

**Purpose:** Combines multiple subtle inefficiencies requiring deep analysis for optimization.

**Gas Inefficiencies (Expert difficulty to detect):**

- **Problem 1: Multiple severely non-optimally packed structs**  
  The `UserInfo` struct uses **4 storage slots** instead of 2:
  ```
  struct UserInfo {
      bool active;        // 1 byte   → slot 0 (wastes 31 bytes)
      uint256 largeData;  // 32 bytes → slot 1 (forces new slot)
      uint48 quota;       // 6 bytes  → slot 2 (can't go back to slot 0)
      uint64 score;       // 8 bytes  → slot 3 (can't fit in previous slots)
      // Total: 4 slots but could use 2 with reordering!
  }
  ```
  **Optimal packing:**
  ```
  struct UserInfo {
      uint256 largeData;  // 32 bytes → slot 0
      uint64 score;       // 8 bytes  → slot 1
      uint48 quota;       // 6 bytes  → slot 1
      bool active;        // 1 byte   → slot 1
      // = 47 bytes → 2 slots total
  }
  ```

- **Problem 2: Another poorly packed struct**  
  The `Config` struct uses **5 slots** instead of 3:
  ```
  struct Config {
      bool enabled;       // 1 byte   → slot 0 (wastes 31 bytes)
      uint128 value1;     // 16 bytes → slot 1 (wastes 16 bytes)
      bool flag1;         // 1 byte   → slot 2 (should be in slot 1!)
      uint128 value2;     // 16 bytes → slot 3 (should be in slot 1!)
      bool flag2;         // 1 byte   → slot 4 (should be in slot 3!)
      // Total: 5 slots but could use 3!
  }
  ```

- **Problem 3: Multiple redundant storage accesses in loop**  
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

- **Problem 4: Inefficient struct updates**  
  Multiple individual field updates instead of single struct assignment:
  ```
  users[user].active = true;    // ❌ Storage write
  users[user].largeData = large; // ❌ Storage write  
  users[user].quota = quota;     // ❌ Storage write
  users[user].score = score;     // ❌ Storage write
  ```

- **Problem 5: Unnecessary SafeMath usage**  
  Using SafeMath when Solidity 0.8+ has built-in overflow checking:
  ```
  rewardPool = rewardPool.add(baseReward);  // ❌ Extra function call + redundant checks
  ```

- **Estimated gas savings:** 70-85% reduction per batch operation

## Optimization Strategy & Expected Improvements

| Contract | Issue Type | Current Gas | Optimized Gas | Savings |
|----------|------------|-------------|---------------|---------|
| ExternalCallInLoop | External calls in loops | ~150,000 | ~30,000 | **80%** |
| UnnecessarySafeMath | SafeMath + redundancy | ~50,000 | ~25,000 | **50%** |
| SimpleStorage | Storage loops + events | ~200,000 | ~40,000 | **80%** |
| WeightedVoting | Struct packing + external calls | ~180,000 | ~55,000 | **70%** |
| AdvancedProcess | Multi-slot structs + complex inefficiencies | ~350,000 | ~70,000 | **80%** |

## Files Structure

```
contracts/
├── ExternalCallInLoop.sol      (Easy: external calls in loops)
├── UnnecessarySafeMath.sol     (Easy: SafeMath in 0.8+)
├── SimpleStorage.sol           (Medium: storage loops, events)
├── WeightedVoting.sol          (Advanced: struct packing + external calls)  
└── AdvancedProcess.sol         (Expert: complex packing + nested inefficiencies)
```

## Key Gas Optimization Categories Tested

1. **Struct Packing** - Multiple poorly packed structs across contracts
2. **Storage Access** - Redundant reads/writes and loop inefficiencies  
3. **External Calls** - Calls inside loops and redundant external access
4. **Arithmetic Operations** - Unnecessary SafeMath and unchecked math
5. **Memory vs Storage** - Inefficient data handling patterns
6. **Loop Optimization** - Array operations and condition checks
7. **Event Emissions** - Events inside loops vs batching

## Dependencies

- **@openzeppelin/contracts** (v5.0.0+)
  - `SafeMath` — arithmetic with overflow protection
  - `EnumerableSet.AddressSet` — gas-efficient enumeration utilities

## References

- [Solidity Gas Optimization Tips](https://soliditylang.org/blog/)
- [OpenZeppelin Gas Optimization Guide](https://docs.openzeppelin.com/contracts/4.x/)
- [EVM Opcode Costs](https://www.evm.codes/)
- [RareSkills Gas Optimization Guide](https://www.rareskills.io/post/gas-optimization)
