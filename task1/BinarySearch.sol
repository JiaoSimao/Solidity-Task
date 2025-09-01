// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract BinarySearch {
    //二分查找：在一个有序数组中查找目标值
    function binarySearch(uint[] memory arr, uint target) public pure returns (int) {
        uint left =0;
        uint right = arr.length -1;

        if (arr.length ==0) {
            return -1;
        }

        while (left <= right) {
            uint mid = left + (right - left) / 2;
            if (arr[mid] == target) {
                return int(mid);
            } else if (arr[mid] < target) {
                left = mid + 1;
            } else {
                // 如果目标值小于中间值，则在左半部分查找
                if (mid ==0) {
                    break;
                }
                right = mid - 1;
            }
        }
        return -1;
    }


}