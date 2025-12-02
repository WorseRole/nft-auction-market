const { ethers, upgrades } = require("hardhat");

async function main() {
    const existingProxyAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // 现有代理地址
    
    const Auction2 = await ethers.getContractFactory("Auction2");
    const upgradedProxy = await upgrades.upgradeProxy(existingProxyAddress, Auction2);
    
    console.log("Auction2 deployed to:", upgradedProxy.address);
}

main();