## 项目需求

### 实现一个 NFT 拍卖市场

目标

1. 使用 Hardhat 框架开发一个 NFT 拍卖市场。
2. 使用 Chainlink 的 feedData 预言机功能，计算 ERC20 和以太坊到美元的价格。
3. 使用 UUPS/透明代理模式实现合约升级。

需求细节：

1. 实现 NFT 拍卖市场
2. NFT 合约：使用 `ERC721` 标准实现一个 NFT 合约。支持 NFT 的铸造和转移。
3. 拍卖合约：实现一个拍卖合约，支持以下功能：创建拍卖：允许用户将 NFT 上架拍卖。出价：允许用户以 ERC20 或以太坊出价。结束拍卖：拍卖结束后，NFT 转移给出价最高者，资金转移给卖家。
4. 集成 Chainlink 预言机
5. 价格计算：使用 Chainlink 的 feedData 预言机，获取 ERC20 和以太坊到美元的价格。在拍卖合约中，将出价金额转换为美元，方便用户比较。
6. 合约升级UUPS/透明代理：使用 UUPS 或透明代理模式实现合约升级。
7. 测试与部署测试：编写单元测试和集成测试，覆盖所有功能。部署：使用 Hardhat 部署脚本，将合约部署到测试网（如 Sepolia）。

要求

1. 代码质量：代码清晰、规范，符合 Solidity 最佳实践。
2. 功能完整性：实现所有要求的功能，包括 NFT 拍卖、价格计算和合约升级。
3. 测试覆盖率：编写全面的测试，覆盖所有功能。
4. 文档：提供详细的文档，包括项目结构、功能说明和部署步骤。

具体事项

1. 代码：提交完整的 Hardhat 项目代码。
2. 测试报告：提交测试报告，包括测试覆盖率和测试结果。
3. 部署地址：提交部署到测试网的合约地址。
4. 文档：提交项目文档，包括功能说明和部署步骤。

额外挑战（可选）

1. 动态手续费：根据拍卖金额动态调整手续费。



下面我们一步一步来实现一下：

## 项目初始化

### 使用 Hardhat 初始化项目：

```bash
npx hardhat init
```

### 项目依赖安装

```bash
# 安装必要的 TypeScript 类型定义
npm install --save-dev @types/node typescript ts-node
npm install @openzeppelin/contracts @openzeppelin/contracts-upgradeable
npm install @chainlink/contracts
```

### 项目结构（TypeScript 版本）

~~~text
nft-auction-market/
├── contracts/                 # Solidity 合约
│   ├── tokens/
│   │   └── MyNFT.sol
│   └── auction/
├── scripts/                   # TypeScript 部署脚本
│   ├── deploy/
│   └── upgrade/
├── test/                      # 测试文件
├── types/                     # 自定义 TypeScript 类型定义
├── hardhat.config.ts          # TypeScript 配置文件
├── tsconfig.json              # TypeScript 配置
└── package.json
~~~



开始开发：

1. ### 阶段1：创建 MyNFT 合约

   * **编写 MyNFT.sol 合约** (ERC721实现)

   * **编译合约**验证语法

   * **编写测试文件**

   * **运行测试**验证功能

   * **创建部署脚本**

   ### 阶段2：开发拍卖合约

   * **编写 AuctionMarket.sol** (可升级合约)

   * **编译和测试拍卖合约**

   * **创建拍卖合约部署脚本**

