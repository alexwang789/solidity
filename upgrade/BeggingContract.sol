// SPDX-License-Identifier: MIT

// 合约应包含以下功能：
// 一个 mapping 来记录每个捐赠者的捐赠金额。
// 一个 donate 函数，允许用户向合约发送以太币，并记录捐赠信息。
// 一个 withdraw 函数，允许合约所有者提取所有资金。
// 一个 getDonation 函数，允许查询某个地址的捐赠金额。
// 使用 payable 修饰符和 address.transfer 实现支付和提款

// 任务要求
// 合约代码：
// 使用 mapping 记录捐赠者的地址和金额。
// 使用 payable 修饰符实现 donate 和 withdraw 函数。
// 使用 onlyOwner 修饰符限制 withdraw 函数只能由合约所有者调用
pragma solidity ^0.8.0;

contract BeggingContract{
    mapping(address => uint256) public donations;
    address public owner;
    uint256 public totalDonations;

    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    function donate() public  payable{
        require(msg.value >0,"Donation amount must be greater than 0");
        donations[msg.sender] += msg.value;
        totalDonations += msg.value;
    }
    function withdraw() external onlyOwner{
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(msg.sender).transfer(balance);
    }
    function getDonation(address _donator) external view returns(uint256){
        return donations[_donator];
    }
    function getBalance() external view returns(uint256){
        return address(this).balance;
    }
    function getOwner() external view returns(address){
        return owner;
    }

    receive() external payable { 
        donate();
    }

    fallback() external payable {
        donate();
     }

}

