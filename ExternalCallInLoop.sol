// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IToken {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract ExternalCallInLoop {
    IToken token;
    address[] recipients;
    
    constructor(IToken _token) {
        token = _token;
    }
    
    // ❌ GAS BUG: External call in loop
    // Should cache token.balance outside loop
    function distributeToMany(uint256[] calldata amounts) external {
        for (uint i = 0; i < recipients.length; i++) {
            // ← EXTERNAL CALL INSIDE LOOP
            token.transfer(recipients[i], amounts[i]);
        }
    }
}
