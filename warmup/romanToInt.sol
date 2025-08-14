//罗马数字转整数
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RomanToInt{
    function romanToInt(string memory s) public pure returns (uint256){
        uint256 result;
        uint256 prevValue;
        uint256 i;
        mapping (string => uint256) public romanValues;
    
        romanValues["I"] = 1;
        romanValues["V"] = 5;
        romanValues["X"] = 10;
        romanValues["L"] = 50;
        romanValues["C"] = 100;
        romanValues["D"] = 500;
        romanValues["M"] = 1000;

        for(i=0; i<s.length; i++){
            uint256 currentValue = romanValues[string(abi.encodePacked(s[i]))];
            if(currentValue > prevValue){
                result = result + currentValue - 2 * prevValue;
            }else{
                result = result + currentValue;
            }
            prevValue = currentValue;
        }
        return result;
    }

        
}
