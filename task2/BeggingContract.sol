// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

contract BeggingContract {
    //mapping 记录每个捐赠者的捐赠金额
    mapping (address => uint256) public donateAmounts;
    address public owner;
    address[] public doners;

    constructor(address _owner){
        owner = _owner;
    }

    //onlyOwner 修饰符限制withdrawn函数只能合约所有者钓鱼
    modifier onlyOwner {
        require(msg.sender == owner, "only owner can withdrawn");
        _;
    }
    //时间限制，只有在特定时间段内才能捐赠
    modifier limitTime {
        require((isDonateTime() >= 8 && isDonateTime() <=12),"donate time exceed" );
        _;
    }

    event CallFailed(address, uint256, string);
    event Donation(address, uint256);
    event Withdrawn(address, uint256, string);

    //一个donate函数记录每个捐赠者的金额
    function donate() public limitTime payable returns(bool) {
        require(msg.value >0, "donate amount musst greather than 0");
        if (donateAmounts[msg.sender] == 0) {
            //如果是新的捐赠者就添加到捐赠者列表，以免重复添加
            doners.push(msg.sender);
        }
        donateAmounts[msg.sender] += msg.value;
        (bool success,) = address(this).call{value: msg.value}("");
        if (!success) {
            emit CallFailed(msg.sender, msg.value, "donate failed");
            return false;
        }
        
        emit Donation(msg.sender, msg.value);
        return true;
    }

    //一个withdrawn函数允许合约所有者提取所有资金
    function withdrawn() public onlyOwner {
        uint balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
            emit Withdrawn(msg.sender, balance, "withdrawn success");
        }
        emit Withdrawn(msg.sender, balance, "withdrawn failed");
    }

    //查询某个地址的捐赠金额
    function getDonation(address donateAddr) public view returns(uint256){
        require(donateAddr != address(0), "query address cannot be address 0");
        return donateAmounts[donateAddr];
    }

    //捐赠排行榜：实现一个功能，现实捐赠金额最多的前三个地址
    function getTopThreeDonateAddr() public view returns(address[] memory) {
        address[] memory topThree = new address[](3);
        if(doners.length == 0) {
            return topThree;
        }
        uint256 donersCount = doners.length;

        address[] memory tempAddrs = new address[](donersCount);
        uint256[] memory tempDonateAmount = new uint256[](donersCount);

        for (uint256 i = 0; i < donersCount; i++) {
            tempAddrs[i] = doners[i];
            tempDonateAmount[i] = donateAmounts[doners[i]];
        }

        for (uint256 i = 0; i < donersCount; i++) {
            for (uint256 j = i + 1; j<donersCount; j++) {
                if (tempDonateAmount[i] < tempDonateAmount[j]) {
                    uint256 temAmount = tempDonateAmount[i];
                    tempDonateAmount[i] = tempDonateAmount[j];
                    tempDonateAmount[j] = temAmount;

                    address temAddr = tempAddrs[i];
                    tempAddrs[i] = tempAddrs[j];
                    tempAddrs[j] = temAddr;
                }
            }
        }
        
        uint256 limit = donersCount < 3 ? donersCount : 3;
        for (uint256 i = 0; i < limit; i++) {
            topThree[i] = tempAddrs[i];
        }

        return topThree;
    }

    //获取当前区块时间所在的hour
    function isDonateTime() public view returns(uint256) {
        //当前区块时间
        uint256 time = (block.timestamp / 3600) % 24;
        return time;
    }
    
}