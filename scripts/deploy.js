// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  const ENTRYPOINT ="0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789";
  const proxyContract = await hre.ethers.deployContract("ProxyContract", [ENTRYPOINT]);

  await proxyContract.waitForDeployment();

  console.log("proxyContract deployed to:",  proxyContract.getAddress()
  );

  const smartWallet = await hre.ethers.deployContract("SmartWallet", [ENTRYPOINT, proxyContract.target]);

  await smartWallet.waitForDeployment();

  console.log("smartWallet deployed to:", smartWallet.getAddress()
  );
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});