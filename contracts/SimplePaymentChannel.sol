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
  function close(uint256 amount, bytes memory signature) external {
    require(msg.sender == recipient, 'Recipient only');
    require(isValidSignature(amount, signature), 'Invalid signature');
  }

  // 验证签名
  function isValidSignature(uint256 amount, bytes memory signature) internal view returns (bool) {
    bytes32 message = prefixed(keccak256(abi.encodePacked(this, amount)));
    // 检查签名是否来自付款方
    return recoverSigner(message, signature) == sender;
  }

  function recoverSigner(
    bytes32 message,
    bytes memory sig
  ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {}

  /// 构建一个前缀哈希值以模仿以太坊的签名行为
  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
  }
}
