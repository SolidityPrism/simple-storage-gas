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
    uint256 public anotherCounter;
    
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
    
    // ❌ GAS BUG: Repeated storage access
    function doubleIncrement() external {
        counter = counter.add(1); // ← 1st storage access
        counter = counter.add(1); // ← 2nd storage access (wasteful)
    }
    
    // ❌ GAS BUG: Inefficient boolean checks
    function complexOperation(uint256 x) external {
        if (x > 0) {
            counter = counter.add(x);
        } else {
            counter = counter.sub(1);
        }
        
        // ← Redundant condition check
        if (x != 0) {
            anotherCounter = anotherCounter.add(x);
        }
    }
}