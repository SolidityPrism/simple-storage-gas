// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./SimpleStorage.sol";

contract WeightedVoting {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Vote {
        bool yes;
        uint64 weight; // 8 bytes (tip: can be packed)
        address voter;
    }

    EnumerableSet.AddressSet private voters;

    mapping(address => Vote) public votes;
    uint256 public totalVotes;

    SimpleStorage public storageDep;

    constructor(address _storageDep) {
        storageDep = SimpleStorage(_storageDep);
    }

    // GAS AMÉDIUM : struct non packée (32 + 8 + 20 = trois slots)
    // accès storage dans la boucle
    function submitVote(bool yes, uint64 weight) public {
        // Redondant avec presence du mapping, et utilise trop de slots
        require(!voters.contains(msg.sender), "Already voted");
        voters.add(msg.sender);
        votes[msg.sender] = Vote(yes, weight, msg.sender);
        totalVotes += weight;
    }

    // Petit effet : surutilisation de stockage
    function sumWithIncentive() public view returns (uint256) {
        uint256 s = storageDep.sum();
        return s + (totalVotes % 7);
    }
}
