const { ethers } = require('hardhat');
const {JsonRpcProvider} = require('ethers');

const { expect } = require("chai");



describe("ProxyContract", async function () {
  let proxyContract;
  let smartWallet;
  let owner;
  let addr1;
  let addr2;

  async function deploy() {

    // Deploy ProxyContract
    const ENTRYPOINT ="0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789";
    const proxyContract = await hre.ethers.deployContract("ProxyContract", [ENTRYPOINT]);
  
    await proxyContract.waitForDeployment();
  
    console.log("proxyContract deployed to:", proxyContract.target
    );
  
    const smartWallet = await hre.ethers.deployContract("SmartWallet", [ENTRYPOINT, proxyContract.target]);
  
    await smartWallet.waitForDeployment();
  
    console.log("smartWallet deployed to:", smartWallet.target
    );
  };

  before("Before", async () => {
      // Initialize ethers provider and signer
      const provider = new ethers.providers.JsonRpcProvider();
      const [signer, addr1Signer, addr2Signer] = await ethers.getSigners();
      owner = signer;
      addr1 = addr1Signer;
      addr2 = addr2Signer;
  })

  it("Should create smart wallet", async function () {
    const owners = ["addr1.address"];
    const salt = 456;
    await expect(proxyContract.createSmartWallet(owners, salt))
      .to.emit(proxyContract, "WalletDestroyed")
      .withArgs();
  });

  it("Should deposit and withdraw from wallet", async function () {
    // Deposit
    const depositAmount = ethers.utils.parseEther("1");
    await walletContract.connect(addr1).deposit({ value: depositAmount });

    // Check balance
    const balanceBeforeWithdrawal = await provider.getBalance(walletContract.address);
    expect(balanceBeforeWithdrawal).to.equal(depositAmount);

    // Withdraw
    await expect(walletContract.connect(addr1).withdraw(depositAmount))
      .to.emit(walletContract, "Withdrawal")
      .withArgs(addr1.address, depositAmount);

    // Check balance after withdrawal
    const balanceAfterWithdrawal = await provider.getBalance(walletContract.address);
    expect(balanceAfterWithdrawal).to.equal(0);
  });
});
