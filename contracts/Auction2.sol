// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Auction.sol";

contract AuctionV2 is Auction {
    // 重要：不要添加任何新的状态变量！
    // 否则会破坏存储布局
    
    // 添加一个新函数作为升级标记
    function sayHello() public pure returns (string memory) {
        return "Hello, World! from V2";
    }
    
    // 可选：一个读取现有状态的新函数
    function getDoubleFee() public view returns (uint256) {
        // auctionFee 继承自 Auction 合约
        return auctionFee * 2;
    }
    
    // 确保 _authorizeUpgrade 被正确继承
    // 如果不重写，它会使用 Auction 合约中的实现
}