//将两个有序数组合并为一个有序数组

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MergeTwoSortedArray {
    function mergeTwoSortedArray(uint[] memory nums1, uint[] memory nums2) public pure returns (uint[] memory) {
        uint[] memory mergedArray = new uint[](nums1.length + nums2.length);
        uint i = 0;
        uint j = 0;
        uint k = 0;
        while (i < nums1.length && j < nums2.length) {
            if (nums1[i] < nums2[j]) {
                mergedArray[k] = nums1[i];
                i++;
            } else {
                mergedArray[k] = nums2[j];
                j++;
            }
            k++;
        }
        while (i < nums1.length) {
            mergedArray[k] = nums1[i];
            i++;
            k++;
        }
        while (j < nums2
            .length) {
            mergedArray[k] = nums2[j];
            j++;
            k++;
        }
        return mergedArray;
    }
}
