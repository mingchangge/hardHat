// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// 委托投票

contract Ballot {
  //投票者
  struct Voter {
    uint weight; // 计票的权重
    bool voted; // 若为真，代表该人已经投票
    address delegate; // 被委托人
    uint vote; // 投票提案的索引
  }
  //提案
  struct Proposal {
    bytes32 name; // 提案的简称
    uint voteCount; // 得票数
  }

  address public chairperson; // 投票发起人
  mapping(address => Voter) public voters; // 投票者,状态变量
  Proposal[] public proposals; // 提案-结构类型的动态数组

  /// 创建一个新的投票，其中包含proposalNames个提案
  constructor(bytes32[] memory proposalsNames) {
    chairperson = msg.sender;
    voters[chairperson].weight = 1;
    // For each of the provided proposal names,
    for (uint i = 0; i < proposalsNames.length; i++) {
      proposals.push(Proposal({name: proposalsNames[i], voteCount: 0}));
    }
  }

  /**
   * interal - 函数只能通过内部访问（当前合约或者继承的合约），可在当前合约或继承合约中调用。类似于Java的protected
   * public - public标识的函数是合约接口的一部分。可以通过内部，或者消息来进行调用。与Java的public含义一致。
   * external - external标识的函数是合约接口的一部分。函数只能通过外部的方式调用。外部函数在接收大的数组时更有效。Java中无与此对应的关键字。
   * private - 只能在当前合约内访问，在继承合约中都不可访问。与Java中的private含义一致。
   *
   * @param voter The address to be granted voting rights
   * @dev 授权一个地址可以投票
   * @notice 只有投票发起人可以调用
   *
   */
  function giveRightToVote(address voter) external {
    /**
     * require(bool condition) - 检查条件是否满足，如果不满足则抛出异常，终止执行。
     * 若 `require` 的第一个参数的计算结果为 `false`，则终止执行，撤销所有对状态和以太币余额的改动。
     * 在旧版的 EVM 中这曾经会消耗所有 gas，但现在不会了。
     * 可以使用 require 来检查函数是否被正确地调用，或者对传递给函数的参数进行有效性检查。
     * 也可以在 `require` 的第二个参数中提供一个对错误情况的解释。
     */
    /**
     * 当使用 Solidity 编写智能合约时，有时候会遇到错误信息字符串包含中文字符的情况，
     * 然而，Solidity 只支持使用 ASCII 字符作为字符串的内容，因此直接在字符串中使用中文字符会导致编译错误。
     * 为了解决这个问题，我们可以使用 Unicode 转义序列来表示中文字符，例如，使用 \u 后跟 Unicode 编码来表示中文字符。
     * https://www.jyshare.com/front-end/3602/
     */
    require(
      msg.sender == chairperson,
      '\u53ea\u6709\u6295\u7968\u53d1\u8d77\u4eba\u624d\u80fd\u8d4b\u4e88\u6295\u7968\u6743'
    ); //'只有投票发起人才能赋予投票权'
    require(!voters[voter].voted, 'The voter already voted.');
    require(voters[voter].weight == 0);
    voters[voter].weight = 1;
  }

  /// 委托投票
  function delegate(address to) external {
    Voter storage sender = voters[msg.sender];
    require(sender.weight != 0, 'You have no right to vote.');
    require(!sender.voted, 'You already voted.');
    require(to != msg.sender, 'Self-delegation is disallowed.');
    // 委托是可以传递的，只要被委托者 `to` 也设置了委托。
    // 一般来说，这种循环委托是危险的。如果传递太多次，传递的链条太长, 可能需要消耗的gas就会超过一个区块中的可用数量,从而导致委托失败。
    while (voters[to].delegate != address(0)) {
      to = voters[to].delegate;
      // 不允许闭环委托
      require(to != msg.sender, 'Found loop in delegation.');
    }
    Voter storage delegate_ = voters[to];
    //投票者不能将投票权委托给不能投票的账户。
    require(delegate_.weight >= 1);
    sender.voted = true;
    sender.delegate = to;
    if (delegate_.voted) {
      // 如果被委托者已经投过票了，直接增加投票数
      proposals[delegate_.vote].voteCount += sender.weight;
    } else {
      // 如果被委托者还没有投票，增加被委托者的权重
      delegate_.weight += sender.weight;
    }
  }

  /// 投票
  function vote(uint proposal) external {
    Voter storage sender = voters[msg.sender];
    require(sender.weight != 0, 'Has no right to vote.');
    require(!sender.voted, 'Already voted.');
    sender.voted = true;
    sender.vote = proposal;
    // 如果 `proposal` 超过了数组的范围，则会自动抛出异常，并恢复所有的改动
    proposals[proposal].voteCount += sender.weight;
  }

  /// @dev 结束投票，计算胜出的提案
  function winningProposal() public view returns (uint winningProposal_) {
    uint winningVoteCount = 0;
    for (uint p = 0; p < proposals.length; p++) {
      if (proposals[p].voteCount > winningVoteCount) {
        winningVoteCount = proposals[p].voteCount;
        winningProposal_ = p;
      }
    }
    return winningProposal_;
  }

  /// 调用winningProposal()函数获取胜出的提案的索引
  function winnerName() external view returns (bytes32 winnerName_) {
    winnerName_ = proposals[winningProposal()].name;
  }
}
