// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ExternalCallInLoop {
    IToken token;
    address[] recipients;
    
    constructor(IToken _token) {
        token = _token;
    }
    
    // ❌ GAS BUG: External call in loop
    function distributeToMany(uint256[] calldata amounts) external {
        for (uint i = 0; i < recipients.length; i++) {
            // ← EXTERNAL CALL INSIDE LOOP
            token.transfer(recipients[i], amounts[i]);
        }
    }
    
    // ❌ GAS BUG: Multiple external calls for same data
    function checkBalances() external view returns (uint256) {
        uint256 total;
        for (uint i = 0; i < recipients.length; i++) {
            // ← EXTERNAL CALL INSIDE LOOP (could cache length)
            total += token.balanceOf(recipients[i]);
        }
        return total;
    }
    
    // ❌ GAS BUG: Inefficient array initialization
    function addRecipients(address[] calldata newRecipients) external {
        for (uint i = 0; i < newRecipients.length; i++) {
            recipients.push(newRecipients[i]); // ← PUSH IN LOOP
        }
    }
}