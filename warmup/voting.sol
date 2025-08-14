// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// 创建一个名为Voting的合约，包含以下功能：
// 一个mapping来存储候选人的得票数
// 一个vote函数，允许用户投票给某个候选人
// 一个getVotes函数，返回某个候选人的得票数
// 一个resetVotes函数，重置所有候选人的得票数

contract Voting {
    address public voter;
    string [] public candidatesList;
    mapping (string => uint256) public voteReceived;
    

    function vote(string memory _candidate) public {
       candidatesList.push(_candidate);
       voteReceived[_candidate] += 1;
    }

    function getVotes(string memory _candidate) public view returns (uint256) {
        return voteReceived[_candidate];
    }

    function resetVotes() public {
        for(uint256 i =0; i < candidatesList.length; i++){
            voteReceived[candidatesList[i]] = 0;
        }

    }
}
