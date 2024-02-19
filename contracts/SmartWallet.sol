// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {UserOperation} from "@account-abstraction/contracts/interfaces/UserOperation.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract SmartWallet is  Initializable, UUPSUpgradeable {
    using ECDSA for bytes32;
    address[] public owners;
    address public immutable proxyContract;
    IEntryPoint private immutable _entryPoint;

    event WalletInitialized(IEntryPoint indexed entryPoint, address[] owners);

    modifier _requireFromEntryPointOrProxy() {
    require(
        msg.sender == address(_entryPoint) || msg.sender == proxyContract,
        "only entry point or wallet factory can call"
    );
    _;
    }

    constructor(IEntryPoint anEntryPoint, address proxy_Contract) {
        _entryPoint = anEntryPoint;
        proxyContract = proxy_Contract;
    }

    function entryPoint() public view returns (IEntryPoint) {
    return _entryPoint;
    }
    
    function initialize(address[] memory initialOwners) public initializer {
    _initialize(initialOwners);
    }

    function _initialize(address[] memory initialOwners) internal {
    require(initialOwners.length > 0, "no owners");
    owners = initialOwners;
    emit WalletInitialized(_entryPoint, initialOwners);
    }

    function _call(address target, uint256 value, bytes memory data) internal {
    (bool success, bytes memory result) = target.call{value: value}(data);
    if (!success) {
        assembly {
            // The assembly code here skips the first 32 bytes of the result, which contains the length of data.
            // It then loads the actual error message using mload and calls revert with this error message.
            revert(add(result, 32), mload(result))
        }
    }
    }

    function deposit(
    address dest,
    uint256 value,
    bytes calldata func
    ) external payable _requireFromEntryPointOrProxy {
    _call(dest, value, func);
    }


    function _authorizeUpgrade(
        address
    ) internal view override _requireFromEntryPointOrProxy {}



function getDeposit() public view returns (uint256) {

    return entryPoint().balanceOf(address(this));

}

function addDeposit() public payable {

    entryPoint().depositTo{value: msg.value}(address(this));

}

function withdraw(uint256 amount, address payable recipient) external _requireFromEntryPointOrProxy {
    require(amount <= address(this).balance, "Insufficient balance");
    recipient.transfer(amount);
}

receive() external payable {}

}