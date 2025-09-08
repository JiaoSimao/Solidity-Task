const { ethers, getNamedAccounts, deployments } = require("hardhat")
const { expect } = require("chai")

describe("test the hj NFT", function () {
    let singer, buyer, hjnft, hjnftAddress, mintTx
    beforeEach(async function () {
        [singer, buyer] = await ethers.getSigners()
        // await deployments.fixture(["HJNFT"])
        // const HJNFT = await deployments.get("HJNFT")
        // hjnft = await ethers.getContractAt("HJNFT", HJNFT.address, {})
        const hjnftFactroy = await ethers.getContractFactory("HJNFT");
        hjnft = await hjnftFactroy.deploy("HJNFT", "HJN");
        await hjnft.waitForDeployment();
        hjnftAddress = await hjnft.getAddress();
        console.log("HJNFT deployed to:", hjnftAddress);

        //铸造NFT
        mintTx = await hjnft.connect(singer).safeMint(singer.address, "https://flexible-beige-felidae.myfilebase.com/ipfs/QmWz5kkiz9rPwVNHDMVubn35PwRzHYvEWjGMsA1ExBtGkm")
        await mintTx.wait()
        console.log("tx from :", await mintTx.from);
        console.log("tx to :", await mintTx.to);
    })

    it("检查获取的铸币是否正确", async function () {
        //测试铸造的NFT的tokenid和URI是否正确
        const tokenId = 0
        const owner = await hjnft.ownerOf(tokenId)
        expect(owner).to.equal(singer.address)
        const tokenURI = await hjnft.tokenURI(tokenId)
        expect(tokenURI).to.equal("https://flexible-beige-felidae.myfilebase.com/ipfs/QmWz5kkiz9rPwVNHDMVubn35PwRzHYvEWjGMsA1ExBtGkm")
        //判断交易的接受者是不是合约地址
        expect(mintTx.to).to.equal(hjnftAddress)
    })

})