const { ethers } = require('ethers');

// ABI and address of ProxyContract
const {proxyContractABI} = require("./ProxyContract.json");

const proxyContractAddress = '0xCb43a78E3EF1EA967a53dc024fCE1fC3B4C88226';

// ABI and address of Wallet contract
const {walletABI}=  require("./SmartWallet.json");

const walletAddress = '0x91E1918AF2beD51c90d1d24Be4e56530D35c0335';

// Connect to MetaMask
const main = async() => {


async function connectToMetaMask() {
  try {
    // Request account access if needed
    await window.ethereum.request({ method: 'eth_requestAccounts' });
    console.log('Connected to MetaMask');
  } catch (error) {
    console.error('Error connecting to MetaMask:', error);
  }
}

// Create ethers provider
const provider = new ethers.providers.Web3Provider(window.ethereum);
const account = await provider.send("eth_requestAccounts", []);
console.log(account);

// Get contract instances
const proxyContract = new ethers.Contract(proxyContractAddress, proxyContractABI, provider.getSigner());
const walletContract = new ethers.Contract(walletAddress, walletABI, provider.getSigner());

// Function to create a smart wallet
async function createSmartWallet(owners, salt) {
  try {
    const result = await proxyContract.createSmartWallet(owners, salt);
    console.log('Smart wallet created:', result.events.WalletCreated.returnValues.wallet);
  } catch (error) {
    console.error('Error creating smart wallet:', error);
  }
}

// Function to deposit funds into the wallet
async function depositToWallet(amount) {
  try {
    const result = await walletContract.deposit({ value: ethers.utils.parseEther(amount.toString()) });
    console.log('Deposit successful. Transaction hash:', result.hash);
  } catch (error) {
    console.error('Error depositing funds:', error);
  }
}

// Function to withdraw funds from the wallet
async function withdrawFromWallet(amount) {
  try {
    const result = await walletContract.withdraw(ethers.utils.parseEther(amount.toString()));
    console.log('Withdrawal successful. Transaction hash:', result.hash);
  } catch (error) {
    console.error('Error withdrawing funds:', error);
  }
}

// Call the function to connect to MetaMask
connectToMetaMask();
}


