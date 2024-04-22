// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

contract Purchase {
  uint public value;
  address payable public seller;
  address payable public buyer;

  //枚举
  enum State {
    Created,
    Locked,
    Release,
    Inactive
  }
  State public state;

  // 错误
  /// 只有买家可以调用
  error OnlyBuyer();
  /// 只有卖家可以调用
  error OnlySeller();
  /// 状态不匹配
  error InvalidState();
  /// 需提供偶数值
  error ValueNotEven();

  //修饰符
  modifier condition(bool _condition) {
    require(_condition);
    _;
  }
  modifier onlyBuyer() {
    if (msg.sender != buyer) {
      revert OnlyBuyer();
    }
    _;
  }
  modifier onlySeller() {
    if (msg.sender != seller) {
      revert OnlySeller();
    }
    _;
  }
  modifier inState(State _state) {
    if (state != _state) {
      revert InvalidState();
    }
    _;
  }

  // 事件
  event Aborted();
  event PurchaseConfirmed();
  event ItemReceived();
  event SellerRefunded();

  constructor() payable {
    seller = payable(msg.sender);
    /**
     *  确保`msg.value`是偶数
     *  如果是奇数，除法会截断
     *  通过检查乘法结果是否等于`msg.value`来检查
     */
    value = msg.value / 2;
    if (2 * value != msg.value) {
      revert ValueNotEven();
    }
  }

  /// 终止购买并回收以太币
  /// 只能由卖家在合同锁定前调用
  function abort() external onlySeller inState(State.Created) {
    emit Aborted();
    state = State.Inactive;
    // 退还以太币给卖家,直接调用transfer，它可以安全的重入。
    // 因为它是最后一个操作，且状态已改变
    seller.transfer(address(this).balance);
  }

  /// 买家确认购买
  /// 交易必须包含两倍的以太币
  /// 以太币将被锁定直到`confirmReceived`被调用
  function confirmPurchase()
    external
    payable
    inState(State.Created)
    condition(msg.value == 2 * value)
  {
    emit PurchaseConfirmed();
    buyer = payable(msg.sender);
    state = State.Locked;
  }

  /// 确认收到商品
  /// 这将释放被锁定的以太币
  function confirmReceived() external onlyBuyer inState(State.Locked) {
    emit ItemReceived();
    // 首先改变状态，以防止重入
    state = State.Release;
    buyer.transfer(value);
  }

  /// 卖家退款
  /// 这将释放被锁定的以太币
  function refundSeller() external onlySeller inState(State.Release) {
    emit SellerRefunded();
    // 首先改变状态，以防止重入
    state = State.Inactive;
    seller.transfer(3 * value);
  }
}
