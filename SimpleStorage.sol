// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleStorage {
    uint256[100] public data;
    uint256 public total;
    uint256 public count;

    // ❌ GAS BUG: Storage writes in loop
    function fillAll(uint256 value) public {
        for (uint256 i = 0; i < 100; i++) {
            data[i] = value; // ← STORAGE WRITE IN LOOP
        }
    }

    // ❌ GAS BUG: Inefficient array summing
    function sum() public view returns (uint256) {
        uint256 s;
        for (uint256 i = 0; i < 100; i++) {
            s += data[i]; // ← STORAGE READ IN LOOP
        }
        return s;
    }

    // ❌ GAS BUG: Redundant calculations
    function calculateStats() external {
        uint256 s1 = sum();  // ← External call + loop
        uint256 s2 = sum();  // ← Same calculation repeated!
        total = s1 + s2;
    }

    // ❌ GAS BUG: Inefficient event usage
    event ValueSet(uint256 index, uint256 value);
    
    function setMultipleValues(uint256[] calldata indices, uint256[] calldata values) external {
        for (uint i = 0; i < indices.length; i++) {
            data[indices[i]] = values[i];
            emit ValueSet(indices[i], values[i]); // ← EVENT IN LOOP
        }
    }

    // ❌ GAS BUG: Poor loop optimization
    function incrementAll() external {
        for (uint256 i = 0; i < data.length; i++) { // ← .length in condition
            data[i] += 1;
        }
    }
}