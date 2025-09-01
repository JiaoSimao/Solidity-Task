// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract ReverseString {
    //反转一个字符串，输入“abcde” 输出“edcba”
    function reverseString(string memory input) public pure returns(string memory) {
        bytes memory bytesInput = bytes(input);
        bytes memory reversedBytes = new bytes(bytesInput.length);
        
        for (uint i = 0; i < bytesInput.length; i++) {
            reversedBytes[bytesInput.length - i - 1] = bytesInput[i];
        }
        return string(reversedBytes);
    }
}