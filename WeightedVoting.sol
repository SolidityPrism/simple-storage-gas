// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./SimpleStorage.sol";

contract WeightedVoting {
    using EnumerableSet for EnumerableSet.AddressSet;

    // ❌ STRUCT MAL PACKÉE - utilise 4 slots au lieu de 2 !
    struct Vote {
        bool yes;           // 1 byte (slot 0)
        uint256 proposalId; // 32 bytes (slot 1 - forces new slot)
        uint64 weight;      // 8 bytes (slot 2 - can't go back to slot 0)
        address voter;      // 20 bytes (slot 3 - can't fit in slot 2)
        bool executed;      // 1 byte (slot 4 - should be with other bools!)
        // Total: 5 slots but could use 2!
    }

    // ❌ AUTRE STRUCT MAL PACKÉE
    struct Proposal {
        bool active;        // 1 byte (slot 0)
        uint128 minVotes;   // 16 bytes (slot 1)
        uint128 maxVotes;   // 16 bytes (slot 2 - should be in slot 1!)
        bool finalized;     // 1 byte (slot 3 - should be in slot 0!)
        // Total: 4 slots but could use 2!
    }

    EnumerableSet.AddressSet private voters;
    mapping(address => Vote) public votes;
    mapping(uint256 => Proposal) public proposals;
    uint256 public totalVotes;
    uint256 public currentProposalId;

    SimpleStorage public storageDep;

    constructor(address _storageDep) {
        storageDep = SimpleStorage(_storageDep);
    }

    // ❌ GAS BUG: Inefficient struct creation and storage access
    function submitVote(bool yes, uint64 weight) public {
        require(!voters.contains(msg.sender), "Already voted");
        voters.add(msg.sender);
        
        // ❌ Creates struct in memory then copies to storage
        Vote memory newVote = Vote(yes, currentProposalId, weight, msg.sender, false);
        votes[msg.sender] = newVote; // ← INEFFICIENT STRUCT COPY
        
        totalVotes += weight;
    }

    // ❌ GAS BUG: Multiple storage reads for same data
    function getVoteDetails(address voter) external view returns (bool, uint64, bool) {
        Vote storage v = votes[voter]; // ← Storage read
        bool canVote = !voters.contains(voter); // ← Storage read + external call
        uint256 currentId = currentProposalId; // ← Storage read
        
        return (v.yes, v.weight, canVote && v.proposalId == currentId);
    }

    // ❌ GAS BUG: Inefficient loop with external calls
    function batchFinalize(address[] calldata votersList) external {
        for (uint i = 0; i < votersList.length; i++) {
            if (votes[votersList[i]].executed == false) {
                votes[votersList[i]].executed = true; // ← STORAGE WRITE IN LOOP
                // External call in loop
                uint256 currentSum = storageDep.sum(); // ← EXTERNAL CALL IN LOOP
                totalVotes += currentSum % 10;
            }
        }
    }

    // ❌ GAS BUG: Poor condition ordering
    function complexCheck(address user, uint256 threshold) external view returns (bool) {
        // Expensive operations should be last in AND conditions
        return storageDep.sum() > threshold && 
               voters.contains(user) && 
               votes[user].weight > 100; // ← External call first!
    }
}