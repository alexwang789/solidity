//题目描述：反转一个字符串。输入 "abcde"，输出 "edcba"
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Reverse{

    function reverseString(string memory _string) public pure returns (string memory){
        bytes memory _bytes = bytes(_string);
        uint256 len = bytes(_string).length;
        bytes memory _bytesReverse = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            _bytesReverse[i] = _bytes[len - i - 1];
        }
        return string(_bytesReverse);
        
    }

}
