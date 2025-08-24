// SPDX-License-Identifier: MIT

// 合约包含以下标准 ERC20 功能：
// balanceOf：查询账户余额。
// transfer：转账。
// approve 和 transferFrom：授权和代扣转账。
// 使用 event 记录转账和授权操作。
// 提供 mint 函数，允许合约所有者增发代币。
// 提示：
// 使用 mapping 存储账户余额和授权信息。
// 使用 event 定义 Transfer 和 Approval 事件。
// 部署到sepolia 测试网，导入到自己的钱包
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("MyToken", "MTK") {
        _mint(msg.sender, initialSupply);
    }

    //合约所有者
    address public owner = msg.sender;

    //使用mapping存储账户余额
    mapping(address => uint256) private _balances;

    //使用mapping存储授权信息
    mapping(address => mapping(address => uint256)) private _allowances;

    //使用balanceOf查询账户余额
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    //transfer转账
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_balances[msg.sender]>= amount,"Insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        _transfer(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    //approve授权
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[spender][msg.sender] - amount;
        _approve(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    //transferFrom代扣转账
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }



    // 提供mint函数，允许合约所有者增发代币
    function mint(address to, uint256 amount) public {
        require(msg.sender == owner, "Only the owner can mint tokens");
        _mint(to, amount);
    }
 

}
