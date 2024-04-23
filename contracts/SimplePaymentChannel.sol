// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract SimplePaymentChannel {
  // 发送付款的账户
  address payable public sender;
  // 接收付款的账户
  address payable public recipient;
  // 通道关闭时间-超时时间，以防止通道永远不关闭
  uint256 public expiration;

  constructor(address payable recipientAddress, uint256 duration) payable {
    sender = payable(msg.sender);
    recipient = recipientAddress;
    expiration = block.timestamp + duration;
  }

  // 关闭通道并将余额发送给接收者
  function close(uint256 amount, bytes memory signature) external view {
    require(msg.sender == recipient, 'Recipient only');
    require(isValidSignature(amount, signature), 'Invalid signature');
  }

  // 验证签名
  function isValidSignature(uint256 amount, bytes memory signature) internal view returns (bool) {
    bytes32 message = prefixed(keccak256(abi.encodePacked(this, amount)));
    // 检查签名是否来自付款方
    return recoverSigner(message, signature) == sender;
  }

  /// 构建一个前缀哈希值以模仿以太坊的签名行为
  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
  }

  function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
    // splitSignature函数使用 内联汇编 来完成把各部分分离出来（使用 web3.js签名的数据，r, s 和 v 是连接在一起的）
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
    // 在Solidity中还原消息签名者
    // 通常, ECDSA（椭圆曲线数字签名算法） 包含两个参数, r and s. 在以太坊中签名包含第三个参数 v, 它可以用于验证哪一个账号的私钥签署了这个消息。
    // 通过 ecrecover 函数, 我们可以从签名中恢复签名者的地址。
    return ecrecover(message, v, r, s);
  }

  /// 创建和验证签名
  function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
    require(sig.length == 65, 'Invalid signature length');

    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
    return (v, r, s);
  }
}
