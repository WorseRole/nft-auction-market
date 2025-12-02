const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
/**
describe("Auction Contract", function () {
  let nft, auction, owner, seller, bidder;

  beforeEach(async function () {
    [owner, seller, bidder] = await ethers.getSigners();

    // 部署NFT合约
    const NFT = await ethers.getContractFactory("NFT");
    nft = await upgrades.deployProxy(NFT, ["Test NFT", "TNFT"], {
      initializer: "initialize"
    });

    // 部署拍卖合约
    const Auction = await ethers.getContractFactory("Auction");
    auction = await upgrades.deployProxy(Auction, [], {
      initializer: "initialize"
    });
  });

  describe("NFT Contract", function () {
    it("Should mint NFT successfully", async function () {
      await nft.connect(seller).mint(seller.address);
      expect(await nft.ownerOf(1)).to.equal(seller.address);
    });
  });

  // 测试创建拍卖
  describe("Auction Creation", function () {
    it("Should create auction successfully", async function () {
      // 先铸造NFT
      await nft.connect(seller).mint(seller.address);
      await nft.connect(seller).setApprovalForAll(auction.address, true);

      // 创建拍卖
      await expect(
        auction.connect(seller).createAuction(
          nft.address,
          1,
          ethers.utils.parseUnits("50", 8),
          86400
        )
      ).to.emit(auction, "AuctionCreated");
    });
  });


// describe("Bidding", function() {
    // it("Should accept bid and calculate USD value", async function () {
    // 1. 创建拍卖

    // 2. 设置价格预言机（模拟）
    // 这里需要先设置价格预言机地址

    // 3. 出价测试

    // 测试出价和价格计算逻辑


    // it.should("accept bid and calculate USD value", async function () {
    //   console.log("bidder:", bidder.address);
    //   console.log("seller:", seller.address);
    //   console.log("nft:", nft.address);
    //   console.log("auction:", auction.address);
    //   console.log("auction fee:", await auction.auctionFee());
    //   // 当前拍品
      

    //   await auction.connect(bidder).placeBid(1, { value: ethers.utils.parseEther("1") });

    // })
    // });
  // });



});

 */



describe("Contract Upgrade", function () {
    it("Should upgrade contract and preserve state", async function () {
        const [owner] = await ethers.getSigners();
        
        // 1. 部署初始版本 V1
        const AuctionV1 = await ethers.getContractFactory("Auction");
        const auctionProxy = await upgrades.deployProxy(AuctionV1, [], {
            initializer: "initialize"
        });
        await auctionProxy.deployed();
        const proxyAddress = auctionProxy.address;
        
        console.log("V1 合约地址:", proxyAddress);
        
        // 获取初始状态
        const initialFee = await auctionProxy.auctionFee();
        const initialFeeRecipient = await auctionProxy.feeRecipient();
        
        console.log("初始手续费:", initialFee.toString());
        console.log("初始手续费接收者:", initialFeeRecipient);
        
        // 2. 部署新版本 V2 的逻辑合约
        // 先编译 AuctionV2
        console.log("正在编译 AuctionV2...");
        const AuctionV2 = await ethers.getContractFactory("AuctionV2");
        
        // 3. 执行升级
        console.log("正在升级合约...");
        const upgradedAuction = await upgrades.upgradeProxy(proxyAddress, AuctionV2);
        console.log("合约已成功升级至 V2");
        
        // 4. 验证核心内容
        // 4.1 验证代理地址未变
        expect(upgradedAuction.address).to.equal(proxyAddress);
        console.log("✅ 代理地址保持不变:", upgradedAuction.address);
        
        // 4.2 验证原有状态数据保持不变
        const preservedFee = await upgradedAuction.auctionFee();
        const preservedFeeRecipient = await upgradedAuction.feeRecipient();
        
        expect(preservedFee).to.equal(initialFee);
        expect(preservedFeeRecipient).to.equal(initialFeeRecipient);
        console.log("✅ 手续费保持为:", preservedFee.toString());
        console.log("✅ 手续费接收者保持为:", preservedFeeRecipient);
        
        // 4.3 验证新功能可用
        // 调用 AuctionV2 新增的 sayHello 函数
        try {
            const helloMessage = await upgradedAuction.sayHello();
            console.log("✅ 新函数返回:", helloMessage);
            expect(helloMessage).to.equal("Hello, World! from V2");
        } catch (error) {
            // 如果 sayHello 不存在，尝试 getDoubleFee
            console.log("尝试调用 getDoubleFee...");
            const doubleFee = await upgradedAuction.getDoubleFee();
            console.log("✅ getDoubleFee 返回:", doubleFee.toString());
            expect(doubleFee).to.equal(initialFee * 2);
        }
        
        // 4.4 验证原有功能依然工作
        // 测试原有函数是否还能调用
        const currentOwner = await upgradedAuction.owner();
        console.log("✅ 原有 owner 函数正常，所有者:", currentOwner);
        
        console.log("🎉 升级测试全部通过！");
    });
});
