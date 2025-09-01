// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Voting {
    //定一个数组存储mapping的key
    address[] public candidates;

    //一个mapping来存储候选人的投票数
    mapping(address => uint256) public votesReceived;
    //一个vote函数，允许用户投票给某个候选人
    function vote(address _candidate) public {
        if (votesReceived[_candidate] == 0) {
            candidates.push(_candidate);
        }
        votesReceived[_candidate] += 1;
    }
    //一个getVotes函数，返回某个候选人的投票数
    function getVotes(address _candidate) public view returns (uint256) {
        return votesReceived[_candidate];
    }
    //一个resetVotes函数，重置所有候选人的得票数
    function resetVotes() public {
        //循环candidates来重置mapping
        for (uint256 i = 0; i < candidates.length; i++) {
            votesReceived[candidates[i]] = 0;
        }
        
    }

}