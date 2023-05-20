// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// string constant TOKEN_FULL_NAME = "StBFC Token";
// string constant TOKEN_NAME = "stBFC";

contract StBFC is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    //====== Contracts and Addresses ======//
    address public liquidStakingAddress;

    //====== initializer ======//
    function initialize() initializer public {
        __ERC20_init("Stake Bifrost Token", "stBFC");
        __Ownable_init();
    }

    //====== modifier ======//
    modifier onlyLiquidStaking() {
        require(msg.sender == liquidStakingAddress ,"StBFC: caller is not the liquid staking contract");
        _;
    }

    //====== setter Functions ======//
    function setLiquidStakingAddress (address _liquidStakingAddr) onlyOwner external {
        liquidStakingAddress = _liquidStakingAddr;
    }

    //====== service functions ======//
    function mintToken(address _account, uint _amount) onlyLiquidStaking external {
        _mint(_account, _amount);
    }

    function burnToken(address _account, uint _amount) onlyLiquidStaking external  {
        _burn(_account, _amount);
    }
}
