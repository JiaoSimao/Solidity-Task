// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract IntToRoman {
    uint256[] private values = [
        1000,
        900,
        500,
        400,
        100,
        90,
        50,
        40,
        10,
        9,
        5,
        4,
        1
    ];

    string[] private roman = [
        "M",
        "CM",
        "D",
        "CD",
        "C",
        "XC",
        "L",
        "XL",
        "X",
        "IX",
        "V",
        "IV",
        "I"
    ];

    function intToRoman(uint256 num) public view returns (string memory) {
        string memory result = "";
        for (uint256 i = 0; i < values.length; i++) {
            while (num >= values[i]) {
                num -= values[i];
                result = string(abi.encodePacked(result, roman[i]));
            }
        }
        return result;
    }
}
