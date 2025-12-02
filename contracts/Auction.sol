// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceConverter.sol";

contract Auction is UUPSUpgradeable, OwnableUpgradeable {
    using PriceConverter for uint256;

    struct AuctionItem {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        // 改为美元起拍价
        uint256 startPriceInUSD;
        address highestBidder;
        // 出价最高的代币类型
        address highestBidToken;
        uint256 highestBidAmount;
        uint256 highestBidInUSD;
        bool ended;        
    }

    mapping(bytes32 => AuctionItem) public auctions;
    mapping(address => AggregatorV3Interface) public priceFeeds;
    mapping(address => mapping(address => uint256)) public pendingRefunds;

    uint256 public auctionFee; // 手续费
    address public feeRecipient;

    event AuctionCreated(
        bytes32 indexed auctionId, 
        address indexed seller, 
        address nftContract, 
        uint256 tokenId, 
        uint256 startPriceInUSD
    );

    event NewBid(
        bytes32 indexed auctionId,
        address indexed bidder,
        address paymentToken,
        uint256 amount,
        uint256 usdAmount
    );

    event AuctionEnded(
        bytes32 indexed auctionId,
        address indexed winner,
        address paymentToken,
        uint256 amount
    );

    event RefundFailed (
        address indexed to,
        address paymentToken,
        uint256 amount
    );

    event RefundWithdrawn(
        address indexed user,
        address paymentToken,
        uint256 amount
    );

    /**
     * 初始化
     * @dev 初始化拍卖合约
     */
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        auctionFee = 250; // 2.5%
        feeRecipient = msg.sender;
    }

    /**
     * 创建拍卖
     * @param _nftContract NFT合约地址
     * @param _tokenId NFT ID
     * @param _startPriceInUSD 开始价格
     * @param _duration 拍卖时长
     */
    function createAuction(
        address _nftContract,
        uint256 _tokenId,
        uint256 _startPriceInUSD,
        uint256 _duration
    ) external returns (bytes32) {
        require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "Not owner");
        require(IERC721(_nftContract).isApprovedForAll(msg.sender, address(this)), "Not approved");

        bytes32 auctionId = keccak256(abi.encodePacked(_nftContract, _tokenId, block.timestamp));

        auctions[auctionId] = AuctionItem({
            seller: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            startPriceInUSD: _startPriceInUSD,
            highestBidder: address(0),
            highestBidToken: address(0),
            highestBidAmount: 0,
            highestBidInUSD: 0,
            ended: false
        });

        // 根据ERC721代币转移到拍卖合约
        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

        emit AuctionCreated(auctionId, msg.sender, _nftContract, _tokenId, _startPriceInUSD);
        return auctionId;
    }

    /**
     * 出价
     * @param auctionId 拍卖ID
     * @param paymentToken 支付代币
     * @param amount 支付金额
     */
    function placeBid(bytes32 auctionId, address paymentToken, uint256 amount) external payable {
        AuctionItem storage auction = auctions[auctionId]; 
        require(block.timestamp < auction.endTime, "Auction ended");
        require(!auction.ended, "Auction already ended");
        require(paymentToken != address(0) || msg.value > 0, "Invalid payment");

        // 处理支付
        uint256 bidAmount;
        // 支付代币 将代币从发送者转移到拍卖合约
        if(paymentToken == address(0)) {
            // eth
            require(msg.value == amount, "ETH amount mismatch");
            bidAmount = msg.value;
        } else {
            // erc20
            require(msg.value == 0, "Should not send ETH for ERC20 payment");
            bidAmount = amount;
            IERC20(paymentToken).transferFrom(msg.sender, address(this), bidAmount);
        }
        
        // 转为美元来比较
        uint256 usdAmount = _getBidInUSD(paymentToken, bidAmount);
        require(usdAmount > 0, "Invalid bid amount");
        require(usdAmount >= auction.startPriceInUSD, "Bid below start price");
        require(usdAmount > auction.highestBidInUSD, "Bid too low");

        // 处理之前的出价退款，退款失败则记录
        if(auction.highestBidder != address(0)) {
            // 退款 - 将代币从拍卖合约转移到出价者 
            // 代币类型，之前出价最高者地址，之前出价金额
            _refundBid(auction.highestBidToken, auction.highestBidder, auction.highestBidAmount); // 修复：auction highestBid → auction.highestBid
        }

        // 更新最高出价
        auction.highestBidder = msg.sender;
        auction.highestBidToken = paymentToken;
        auction.highestBidAmount = bidAmount;
        auction.highestBidInUSD = usdAmount;

        emit NewBid(auctionId, msg.sender, paymentToken, bidAmount, usdAmount);
    }

    /**
     * 结束拍卖 
     */
    function endAuction(bytes32 auctionId) external { // 修复：EndAuction → endAuction (推荐小写)
        AuctionItem storage auction = auctions[auctionId];
        require(block.timestamp >= auction.endTime, "Auction not ended"); // 改为 >=
        require(!auction.ended, "Auction already ended");
        require(msg.sender == auction.seller || msg.sender == owner(), "Not Authorized");

        auction.ended = true;

        if(auction.highestBidder != address(0)) {
            uint256 fee = (auction.highestBidAmount * auctionFee) / 10000;
            uint256 sellerAmount = auction.highestBidAmount - fee;

            // 转移代币 抽完成给到卖家
            _transferAmount(auction.highestBidToken, auction.seller, sellerAmount);
            _transferAmount(auction.highestBidToken, feeRecipient, fee);
            
            // 转移NFT 把卖家的NFT 给到 买家
            IERC721(auction.nftContract).transferFrom(address(this), auction.highestBidder, auction.tokenId); 

            emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBidToken, auction.highestBidAmount); 
        } else {
            // 流拍了 NFT从拍卖合约转移给了卖家
            IERC721(auction.nftContract).transferFrom(address(this), auction.seller, auction.tokenId);
        }
    }

    function _getBidInUSD(address paymentToken, uint256 amount) internal view returns(uint256) {
        AggregatorV3Interface priceFeed = priceFeeds[paymentToken];
        if(address(priceFeed) == address(0)) {
            return 0;
        }
        return amount.getConversionRate(priceFeed);
    }

    function _refundBid(address paymentToken, address to, uint256 amount) internal {
        _transferAmount(paymentToken, to, amount);
    }

    function _transferAmount(address paymentToken, address to, uint256 amount) internal {
        if (paymentToken == address(0)) {
            // ETH - 使用低级别call，更安全
            (bool success, ) = to.call{value: amount}("");
            if(!success) {
                // 记录失败的
                pendingRefunds[paymentToken][to] += amount;
                emit RefundFailed(to, paymentToken, amount);
            }
            // payable(to).transfer(amount);
        } else {
            // ERC20 -- 使用 try catch
            try IERC20(paymentToken).transfer(to, amount){
                // success
            } catch {
                // 记录失败的
                pendingRefunds[paymentToken][to] += amount;
                emit RefundFailed(to, paymentToken, amount);
            }
        }
    }

    function withdrawRefund(address paymentToken) external {
        uint256 amount = pendingRefunds[paymentToken][msg.sender];
        require(amount > 0, "Nothing to withdraw");
        pendingRefunds[paymentToken][msg.sender] = 0;
        _transferAmount(paymentToken, msg.sender, amount);

        emit RefundWithdrawn(msg.sender, paymentToken, amount);
    }

    function setPriceFeed(address token, address priceFeed) external onlyOwner {
        priceFeeds[token] = AggregatorV3Interface(priceFeed);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
    }
}