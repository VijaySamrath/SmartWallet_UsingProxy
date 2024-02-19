// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {SmartWallet} from "./SmartWallet.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";


contract ProxyContract {
    SmartWallet public immutable walletImplementation;

    // Mapping to track deployment status of each account
    mapping(address => bool) public isSmartWalletDeployed;

    // Event to signal account destruction
    event AccountDestroyed(address indexed accountOwner);

    constructor(IEntryPoint entryPoint) {
        walletImplementation = new SmartWallet(entryPoint, address(this));
    }

    function getAddress(
    address[] memory owners,
    uint256 salt
) public view returns (address) {
    // Encode the initialize function in our wallet with the owners array as an argument into a bytes array
    bytes memory walletInit = abi.encodeCall(SmartWallet.initialize, owners);
    // Encode the proxyContract's constructor arguments which include the address walletImplementation and the walletInit
    bytes memory proxyConstructor = abi.encode(
        address(walletImplementation),
        walletInit
    );
    // Encode the creation code for ERC1967Proxy along with the encoded proxyConstructor data
    bytes memory bytecode = abi.encodePacked(
        type(ERC1967Proxy).creationCode,
        proxyConstructor
    );
    // Compute the keccak256 hash of the bytecode generated
    bytes32 bytecodeHash = keccak256(bytecode);
    // Use the hash and the salt to compute the counterfactual address of the proxy
    return Create2.computeAddress(bytes32(salt), bytecodeHash);
}

function createSmartWallet(
    address[] memory owners,
    uint256 salt
) external returns (SmartWallet) {
    // Get the counterfactual address
    address addr = getAddress(owners, salt);
    // Check if the code at the counterfactual address is non-empty
    uint256 codeSize = addr.code.length;
    if (codeSize > 0) {
        // If the code is non-empty, i.e. account already deployed, return the Wallet at the counterfactual address
        return SmartWallet(payable(addr));
    }

    // If the code is empty, deploy a new Wallet
    bytes memory walletInit = abi.encodeCall(SmartWallet.initialize, owners);
    ERC1967Proxy proxy = new ERC1967Proxy{salt: bytes32(salt)}(
        address(walletImplementation),
        walletInit
    );

    isSmartWalletDeployed[msg.sender] = true;

    // Return the newly deployed Wallet
    return SmartWallet(payable(address(proxy)));

}
  // Internal function to deploy a new Wallet
    function _deployWallet(address[] memory owners, uint256 salt) internal returns (SmartWallet) {
        bytes memory walletInit = abi.encodeWithSignature("initialize(address[])", owners);
        ERC1967Proxy proxy = new ERC1967Proxy{salt: bytes32(salt)}(
            address(walletImplementation),
            walletInit
        );
        return SmartWallet(payable(address(proxy)));
    }

   
 // Function to destroy the user's account
    function destroyAccount(address accountOwner) external {
        require(isSmartWalletDeployed[accountOwner], "Account does not exist");
         // Transfer any remaining Ether to the beneficiary
        payable(accountOwner).transfer(address(this).balance);
        // Update deployment status
        isSmartWalletDeployed[accountOwner] = false;
        // Emit event
        emit AccountDestroyed(accountOwner);
    }

    // Function for the user to request redeployment of their account
    function requestRedeployment(address[] memory owners, uint256 salt) external returns(SmartWallet){
        require(!isSmartWalletDeployed[msg.sender], "Account is already deployed");
        // Deploy a new Wallet for the user
        SmartWallet newWallet = _deployWallet(owners, salt);
        // Update deployment status
        isSmartWalletDeployed[msg.sender] = true;
        // Emit event or perform additional actions
        return newWallet;
    }


}
