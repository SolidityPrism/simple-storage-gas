// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Old SafeMath library (unnecessary in 0.8+)
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "subtraction overflow");
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}

contract UnnecessarySafeMath {
    using SafeMath for uint256;
    
    uint256 public counter;
    
    // ❌ GAS BUG: Unnecessary SafeMath in Solidity 0.8+
    function increment() external {
        // ← SAFEMATH .add() unnecessary
        counter = counter.add(1);
    }
    
    function decrement() external {
        // ← SAFEMATH .sub() unnecessary
        counter = counter.sub(1);
    }
    
    function multiply(uint256 x) external {
        // ← SAFEMATH .mul() unnecessary
        counter = counter.mul(x);
    }
}
