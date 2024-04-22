// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract BlindAuction {
  struct Bid {
    bytes32 blindedBid;
    uint deposit;
  }
  address payable public beneficiary; // 受益人
  uint public biddingEnd; // 竞标结束时间
  uint public revealEnd; // 揭示期结束时间
  bool public ended;

  mapping(address => Bid[]) public bids;
  address public highestBidder;
  uint public highestBid;
  // 可以取回的之前的竞标
  mapping(address => uint) pendingReturns;

  // 事件
  event AuctionEnded(address winner, uint highestBid);

  //描述失败的错误信息
  /// 该函数被过早调用，在`time`时间再试一次
  error TooEarly(uint time);
  /// 该函数被过晚调用，它不能在 `time` 时间之后被调用。
  error TooLate(uint time);
  ///函数 auctionEnd 已经被调用。
  error AuctionEndAlreadyCalled();

  // 修饰符，用于检查函数调用的时间
  modifier onlyBefore(uint _time) {
    if (block.timestamp >= _time) revert TooLate(_time);
    _;
  }
  modifier onlyAfter(uint _time) {
    if (block.timestamp <= _time) revert TooEarly(_time);
    _;
  }

  constructor(uint biddingTime, uint revealTime, address payable beneficiaryAddress) {
    beneficiary = beneficiaryAddress;
    biddingEnd = block.timestamp + biddingTime;
    revealEnd = biddingEnd + revealTime;
  }

  /**
   * 竞标
   * keccak256(加密哈希)算法则可以将任意长度的输入压缩成64位16进制的数，且哈希碰撞的概率近乎为0.
   */
  /// 可以通过 `_blindedBid` = keccak256(value, fake, secret),设置一个盲拍。
  /// 只有在出价披露阶段被正确披露，已发送的以太币才会被退还。
  /// 如果与出价一起发送的以太币至少为 "value" 且 "fake" 不为真，则出价有效。
  /// 将 "fake" 设置为 true ，
  /// 然后发送满足订金金额但又不与出价相同的金额是隐藏实际出价的方法。
  /// 同一个地址可以放置多个出价。
  function bid(bytes32 _blindedBid) external payable onlyBefore(biddingEnd) {
    bids[msg.sender].push(Bid({blindedBid: _blindedBid, deposit: msg.value}));
  }

  // 揭示出价
  function reveal(
    uint[] calldata values,
    bool[] calldata fakes,
    bytes32[] calldata secrets
  ) external onlyAfter(biddingEnd) onlyBefore(revealEnd) {
    uint length = bids[msg.sender].length;
    require(values.length == length);
    require(fakes.length == length);
    require(secrets.length == length);
    uint refund; // 退款
    for (uint i = 0; i < length; i++) {
      Bid storage bidTocheck = bids[msg.sender][i];
      (uint value, bool fake, bytes32 secret) = (values[i], fakes[i], secrets[i]);
      if (bidTocheck.blindedBid != keccak256(abi.encodePacked(value, fake, secret))) {
        // 出价不匹配
        // 不会退还押金
        continue;
      }
      refund += bidTocheck.deposit;
      // 退还押金
      // 如果出价有效
      if (!fake && bidTocheck.deposit >= value) {
        if (placeBid(msg.sender, value)) {
          refund -= value;
        }
        //清零，使发送者不可能再次认领同一笔订金。
        bidTocheck.blindedBid = bytes32(0);
      }
    }
    payable(msg.sender).transfer(refund);
  }

  /// 撤回过高的出价
  function withdraw() external {
    uint amount = pendingReturns[msg.sender];
    if (amount > 0) {
      // 这里很重要，首先清零，防止接收者多次调用该函数，多次退钱。
      //因为，作为接收调用的一部分，接收者可以在 `transfer` 返回之前重新调用该函数。
      pendingReturns[msg.sender] = 0;
      // 转账
      payable(msg.sender).transfer(amount);
    }
  }

  /// 结束拍卖，并把最高出价发送给受益人
  function AuctionEnd() external onlyAfter(revealEnd) {
    // 判断是否已经结束
    if (ended) revert AuctionEndAlreadyCalled();
    emit AuctionEnded(highestBidder, highestBid);
    // 设置结束标志
    ended = true;
    //发送给受益人
    beneficiary.transfer(highestBid);
  }

  // 这是一个 "internal" 函数，意味着它只能在本合约（或继承合约）内被调用。
  function placeBid(address bidder, uint value) internal returns (bool success) {
    if (value <= highestBid) {
      return false;
    }
    // 判断地址为0或空地址
    if (highestBidder != address(0)) {
      // 将之前的最高出价退还
      pendingReturns[highestBidder] += highestBid;
    }
    highestBid = value;
    highestBidder = bidder;
    return true;
  }
}
