// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./WeightedVoting.sol";

contract AdvancedProcess {
    using SafeMath for uint256;

    // ❌ STRUCT MAL PACKÉE - utilise 3 slots au lieu de 2 !
    struct UserInfo {
        bool active;       // 1 byte (slot 0)
        uint256 largeData; // 32 bytes (slot 1 - force new slot)
        uint48 quota;      // 6 bytes (slot 2 - can't go back to slot 0)
        uint64 score;      // 8 bytes (slot 3 - can't fit in previous slots)
        // Total: 4 slots but could use 2 with reordering!
    }

    // ❌ AUTRE STRUCT MAL PACKÉE
    struct Config {
        bool enabled;      // 1 byte (slot 0)
        uint128 value1;    // 16 bytes (slot 1)
        bool flag1;        // 1 byte (slot 2 - should be in slot 1!)
        uint128 value2;    // 16 bytes (slot 3)
        bool flag2;        // 1 byte (slot 4 - should be in slot 3!)
        // Total: 5 slots but could use 3!
    }

    mapping(address => UserInfo) public users;
    Config public config;

    WeightedVoting public votingDep;

    uint256 public rewardPool;
    uint256 public constant BASE_UNIT = 1e15;

    constructor(address _votingDep) {
        votingDep = WeightedVoting(_votingDep);
    }

    // PROBLÈME GAS : Multiple storage accesses in loop
    function allocateRewards(address[] calldata addrs, uint256 baseReward) public {
        uint256 len = addrs.length;
        for (uint256 i = 0; i < len; i++) {
            if (users[addrs[i]].active) {
                users[addrs[i]].score = uint64(
                    users[addrs[i]].score + baseReward + votingDep.totalVotes()
                );
                rewardPool = rewardPool.add(baseReward); // ← STORAGE WRITE IN LOOP
            }
        }
    }

    // ❌ GAS BUG: Inefficient struct updates
    function updateUser(address user, uint256 large, uint48 quota, uint64 score) external {
        users[user].active = true;    // ← Storage write
        users[user].largeData = large; // ← Storage write  
        users[user].quota = quota;     // ← Storage write
        users[user].score = score;     // ← Storage write
        // Could be done with 1 write by updating entire struct!
    }

    // ❌ GAS BUG: Unchecked math when SafeMath is imported
    function unsafeIncrement() external {
        rewardPool++; // ← Unchecked but SafeMath is imported!
    }
}