// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract RomanToInt {
    mapping (bytes1 => uint) private romanValue;

    constructor() {
        romanValue["I"] = 1;
        romanValue["V"] = 5;
        romanValue["X"] = 10;
        romanValue["L"] = 50;
        romanValue["C"] = 100;
        romanValue["D"] = 500;
        romanValue["M"] = 1000;
    }

    function romanToInt(string memory str) public view returns(uint) {
        bytes memory bytesStr = bytes(str);
        
        uint total = 0;
        uint preValue = 0;
        for (uint i = bytesStr.length -1; i >=0; i--) {
            uint currentValue = romanValue[bytesStr[i]];
            if (currentValue < preValue) {
                total -= currentValue;
            } else {
                total += currentValue;
                
            }
            preValue = currentValue;
            if (i == 0) {
                break;
            }
        }
        return total;
    }

}