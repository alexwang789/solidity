//用 solidity 实现整数转罗马数字
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract RomantoNo{
    function intToRoman(int256 num) public pure returns(string memory){
        string[13] memory symbols = ["M","CM","D","CD","C","XC","L","XL","X","IX","V","IV","I"];
        int256[13] memory values = [1000,900,500,400,100,90,50,40,10,9,5,4,1];
        string memory roman = "";
        for(int i=0;i<13;i++){
            while(num >= values[i]){
                roman = string(abi.encodePacked(roman,symbols[i]));
                num = num - values[i];
            }
        }
        return roman;
    }
}
