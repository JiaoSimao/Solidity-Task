// prepare variables: contract, account
const { ethers, getNamedAccounts } = require("hardhat")
const { expect } = require("chai")


let ccipSimulator, nft, nftPoolLockAndRelease, wnft, nftPoolBureAndMint, firstAccount
let chainSelector
before(async function() {
    firstAccount = (await getNamedAccounts()).firstAccount
    await deployments.fixture(["all"])

    ccipSimulator = await ethers.getContract("CCIPLocalSimulator", firstAccount)
    nft = await ethers.getContract("HJNFT", firstAccount)
    nftPoolLockAndRelease = await ethers.getContract("HJNFTPoolLockAndRelease", firstAccount)
    console.log("nftPoolLockAndRelease address is ", nftPoolLockAndRelease.target)
    wnft = await ethers.getContract("WrappedHJNFT", firstAccount)
    nftPoolBureAndMint = await ethers.getContract("HJNFTPoolBurnAndMint", firstAccount)

    chainSelector = (await ccipSimulator.configuration()).chainSelector_
})


// source chain -> dest chain
describe("source chain -> dest chain", async function() {
    this.beforeEach(async function() {
        await nft.safeMint(firstAccount, "https://flexible-beige-felidae.myfilebase.com/ipfs/QmWz5kkiz9rPwVNHDMVubn35PwRzHYvEWjGMsA1ExBtGkm")
    })
    it("test if user can mint a nft from nft contract successfully", async function() {
        const owner = await nft.ownerOf(0)
        expect(owner).to.equal(firstAccount)
    })

    it("test if user can lock the nft in the pool and send ccip message on source chain", async function() {
        await nft.approve(nftPoolLockAndRelease.target, 0)
        await ccipSimulator.requestLinkFromFaucet(nftPoolLockAndRelease, ethers.parseEther("10"))
        await nftPoolLockAndRelease.lockAndSendNFT(0, firstAccount, chainSelector, nftPoolBureAndMint.target)
        const owner = await nft.ownerOf(0)
        expect(owner).to.equal(nftPoolLockAndRelease)
    })

    it("test if user can get a wrapped nft on dest chain", async function () {
        const owner = await wnft.ownerOf(0)
        expect(owner).to.equal(firstAccount)
    })
})



// dest chain -> source chain
describe("dest chain -> source chain", async function() {
    it("test if user can burn the wnft and send ccip message on dest chain", async function() {
        await wnft.approve(nftPoolBureAndMint.target, 0)
        await ccipSimulator.requestLinkFromFaucet(nftPoolBureAndMint, ethers.parseEther("10"))
        await nftPoolBureAndMint.burnAndSendNFT(0, firstAccount, chainSelector, nftPoolLockAndRelease.target)
        const totalSupply = await wnft.totalSupply()
        
        expect(totalSupply).to.equal(0)

    })

    it("test if user have the nft unlocked on source chain", async function() {
        const owner = await nft.ownerOf(0)
        expect(owner).to.equal(firstAccount)
    })
})
