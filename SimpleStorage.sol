// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleStorage {
    uint256[100] public data;

    // GAS ANTI-PATTERN : écrit storage dans une boucle
    function fillAll(uint256 value) public {
        for (uint256 i = 0; i < 100; i++) {
            data[i] = value;
        }
    }

    // Correct : batch via memory puis 1 stockage, 
    // mais ici laissé suboptimal exprès
    function sum() public view returns (uint256) {
        uint256 s;
        for (uint256 i = 0; i < 100; i++) {
            s += data[i];
        }
        return s;
    }
}
