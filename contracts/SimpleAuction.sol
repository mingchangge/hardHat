// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract SimpleAuction {
  address payable public beneficiary;
  uint public auctionEndTime;
  //拍卖的当前状态
  address public highestBidder;
  uint public highestBid;
  // 允许取回之前的出价
  mapping(address => uint) pendingReturns;
  // 拍卖结束后设为 true，将禁止所有变更
  // 默认初始值为 `false`，即拍卖未结束
  bool ended;
  // 事件-变化时发出事件
  // 事件是能方便地调用以太坊虚拟机日志功能的接口。日志是一种数据，可以被外部的服务或者用户访问。
  event HighestBidIncreased(address bidder, uint amount);
  event AuctionEnded(address winner, uint amount);
  // 错误描述
  // 以下是 natspec 注释，可以通过三个斜杠来识别,它们使用户能够在显示错误或要求用户确认交易时看到该注释信息。
  /// 竞拍已经结束。
  error AuctionAlreadyEnded();
  /// 有更高或相等的出价。
  error BidNotHighEnough(uint highestBid);
  /// 竞拍还没有结束。
  error AuctionNotYetEnded();
  /// 函数“auctionEnd”已经被调用。
  error AuctionEndAlreadyCalled();

  // 构造函数
  constructor(uint _biddingTime, address payable _beneficiary) {
    beneficiary = _beneficiary;
    auctionEndTime = block.timestamp + _biddingTime;
  }

  /// 对拍卖进行出价，具体的出价随交易一起发送。
  /// 如果没有在拍卖中胜出，则返还出价。
  function bid() external payable {
    // payable 如果在函数中涉及到以太币的转移，需要使用到payable关键词。意味着可以在调用这笔函数的消息中附带以太币。
    //如果竞拍已经结束，撤销函数调用
    if (block.timestamp > auctionEndTime) {
      revert AuctionAlreadyEnded();
    }
    // 如果出价不够高，撤销函数调用
    if (msg.value <= highestBid) {
      // revert语句用于中止函数执行并撤销所有更改。
      revert BidNotHighEnough(highestBid);
    }
    if (highestBid != 0) {
      // 简单地使用 highestBidder.send(highestBid) 是危险的，因为它会执行未知合约。
      // 更安全的做法是让接收方自己提取资金。
      pendingReturns[highestBidder] += highestBid;
    }
    highestBidder = msg.sender;
    highestBid = msg.value;
    /**
     * 通过emit调用事件方法，然后这个事件就作为日志记录到了以太坊区块链中。
     * 日志是以太坊区块链中一种特殊的数据结构，只要区块链在，日志就在，日志和产生它的智能合约的地址是绑定的。
     * 日志的作用就是可以被订阅，很多智能合约项目都是传统的web项目+智能合约的这种架构，业务系统有些在链外，
     * 那么链上发生的事情就可以基于这种发布订阅机制进行通知，从而打通链上和链下。
     */
    emit HighestBidIncreased(msg.sender, msg.value);
  }

  /// 撤回出价过高的竞标
  //投标人可以用withdraw()函数撤回他们自己的投标。
  function withdraw() external returns (bool) {
    uint amount = pendingReturns[msg.sender];
    if (amount > 0) {
      pendingReturns[msg.sender] = 0;
      // msg.sender 不属于address payable(与address类型相同，不过有成员函数transfer和send)类型，
      //所以需要进行类型转换
      // `payable(msg.sender)` 类型转换，将地址转换为可支付的地址
      // send 是 transfer 的低级版本。如果执行失败，当前的合约不会因为异常而终止，但 send 会返回 false
      if (!payable(msg.sender).send(amount)) {
        pendingReturns[msg.sender] = amount;
        return false;
      }
    }
    return true;
  }

  /// 结束拍卖，并把最高的出价发送给受益人
  function auctionEnd() external {
    /**
     *  对于可与其他合约交互的函数（意味着它会调用其他函数或发送以太币），
     *  我们可以将结构分成三段：条件检查、执行和与其他合约的交互。
     *  如果这些阶段混在一起，其他的合约可能会回调当前合约并修改状态，
     *  可能导致某些效果（比如支付以太币）多次生效
     *  如果合约内调用的函数包含了与外部合约的交互，则它也会被认为是与外部合约有交互的。
     */
    // 1. 条件检查
    if (block.timestamp < auctionEndTime) {
      /**
       * revert():终止运行并撤销状态更改。
       * revert(string memory reason):终止运行并撤销状态更改，同时返回一个字符串。
       *  Revert特点:
       * 允许你返回一个值,例：revert(‘Something bad happened’);等价于require(condition, ‘Something bad happened’);
       * 它会把所有剩下的gas退回给caller
       */
      revert AuctionNotYetEnded();
    }
    if (ended) {
      revert AuctionEndAlreadyCalled();
    }
    // 2. 执行
    ended = true;
    emit AuctionEnded(highestBidder, highestBid);
    // 3. 与其他合约的交互
    beneficiary.transfer(highestBid);
  }
}
