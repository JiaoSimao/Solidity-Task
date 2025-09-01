// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract MyErc20Token {
    //使用mapping存储账户余额和授权信息
    mapping(address => uint256) public  _balances;
    mapping(address => mapping(address => uint256)) public  _allowances;

    //使用event定义transfer和approval事件
    event TransferAmount(address, address,uint256);
    event Approval(address);

    //提供mint函数，允许合约所有者增发代币
    function mint(address to, uint256 amount) public {
        require(to != address(0), "mint address can not be addrsss 0");
        require(amount > 0, "mint amount must greather than 0");
        _balances[to] += amount;
        emit TransferAmount(address(0), to, amount);
    }

    //查询账户余额
    function balanceOf(address account) public view returns (uint256) {
        require(account != address(0), "mint address can not be addrsss 0");
        return _balances[account];
    }

    //transfer: 转账
    function transfer(address to, uint256 amount) public {
        require(to != address(0), "ERC20: can not transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(_balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit TransferAmount(msg.sender, to, amount);
    }
    //approve: 授权
    function approve(address spender, uint256 amount) public {
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[msg.sender][spender] = amount;
        emit Approval(spender);
    }
    //transfrom 授权和代扣转账
    function transferFrom(address from, address to, uint256 amount) public {
        require(from != address(0), "from address can not be address 0");
        require(to != address(0), "to address can not be address 0");
        require(_balances[from] > amount, "insufficient balance");
        require(_allowances[from][msg.sender] >= amount, "allowance exceeded");

        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;
        emit TransferAmount(from, to, amount);
    }
}