// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract MergeArray {
    //将两个有序数组并成一个有序数组
    function merge(uint[] memory nums1, uint[] memory nums2) public pure returns(uint[] memory) {
        uint[] memory res = new uint[](nums1.length + nums2.length);
        //三个指针
        uint i = 0;
        uint j = 0;
        uint m = 0;

        while (i < nums1.length && j < nums2.length) {
            if (nums1[i] < nums2[j]) {
                res[m] = nums1[i];
                i++;
            }else {
                res[m] = nums2[j];
                j++;
            }
            m++;
        }

        while (i < nums1.length) {
            res[m] = nums1[i];
            i++;
            m++;
        }
        while (j < nums2.length) {
            res[m] = nums2[j];
            j++;
            m++;
        }
        
        return res;
        
    }
}