//使用二分查找在一个有序数组中查找目标值
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract BinarySearch {
    uint[] arr = [1,2,3,4,5,6,7,8,9,10];
    function binarySearch (uint target) public view returns(bool){
        uint left = 0;
        uint right = arr.length -1;
        while (left <= right){
            uint mid = (left + right) / 2;
            if (arr[mid] == target){
                return true;
            }else if (arr[mid] < target){
                left = mid + 1;
            }else {
                right = mid - 1;
            }
        }
        return false;
    }

}
