// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./WeightedVoting.sol";

contract AdvancedProcess {
    using SafeMath for uint256;

    struct UserInfo {
        uint48 quota;      // 6 bytes
        bool active;       // 1 byte
        uint64 score;      // 8 bytes
        // -> gross waste, can be packed; left unoptimized
    }

    mapping(address => UserInfo) public users;

    WeightedVoting public votingDep;

    uint256 public rewardPool;
    uint256 public constant BASE_UNIT = 1e15;

    constructor(address _votingDep) {
        votingDep = WeightedVoting(_votingDep);
    }

    // PROBLÈME GAS : 
    // - packing struct possible
    // - combine deux maps, fait deux accès storage/lecture inutiles
    // - la boucle for est sur storage
    function allocateRewards(address[] calldata addrs, uint256 baseReward) public {
        uint256 len = addrs.length;
        for (uint256 i = 0; i < len; i++) {
            if (users[addrs[i]].active) {
                users[addrs[i]].score = uint64(users[addrs[i]].score + baseReward + votingDep.totalVotes());
                rewardPool = rewardPool.add(baseReward);
            }
        }
    }
}
