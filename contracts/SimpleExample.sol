// SPDX-License-Identifier: UNKNOWN (this is a comment)

pragma solidity ^0.8.24;

contract SimpleExample {
  /**
   * 地址类型(address)存储一个 20 字节的值（以太坊地址的大小）
   * 地址类型也有成员变量，并作为所有合约的基础类型
   * 分为普通的地址和可以转账ETH的地址（payable）
   * payable修饰的地址相对普通地址多了transfer和send两个成员函数
   * 在payable修饰的地址中，send执行失败不会影响当前合约的执行（但是返回false值，需要开发人员检查send返回值）
   * balance和transfer()，可以用来查询ETH余额以及安全转账（内置执行失败的处理）
   * */
  address private _admin;
  uint private _state;
  /**
   * 修饰器（modifier）是solidity特有的语法，类似于面向对象编程中的decorator
   * 声明函数拥有的特性，并减少代码冗余
   * modifier的主要使用场景是运行函数前的检查，例如地址，变量，余额等。
   */
  modifier onlyAdmin() {
    //检查调用者是否为_admin地址
    require(msg.sender == _admin, 'SimpleExample: only admin can call this function');
    // 如果是的话，继续运行函数主体；否则报错并revert交易
    _;
  }
  /**
   * 事件（event）是能方便地调用以太坊虚拟机日志功能的接口。
   * 事件（event）是EVM上日志的抽象，用来记录合约的状态变化
   * 事件是合约的一部分，可以被外部调用
   * 它具有两个特点:
   * 响应：应用程序（ethers.js）可以通过RPC接口订阅和监听这些事件，并在前端做响应;
   * 经济：事件是EVM上比较经济的存储数据的方式，每个大概消耗2,000 gas；相比之下，链上存储一个新变量至少需要20,000 gas。
   */
  event setState(uint state);

  /**
   * 构造函数（constructor）是合约的一部分，用来初始化合约的状态
   * 构造函数只能被调用一次，即合约部署时调用
   * */
  constructor() {
    // 在部署合约的时候，将_admin设置为部署者的地址
    _admin = msg.sender;
  }

  function getState() public view returns (uint) {
    return _state;
  }

  function setStateval(uint state) public onlyAdmin {
    _state = state;
    // 释放事件，记录状态变化
    emit setState(state);
  }
}
