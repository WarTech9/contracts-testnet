//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC4626} from "../tokens/ERC4626.sol";
import {ERC20} from "../tokens/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";
import {MultiAssetPriceOracle, IPriceFeed} from "./MultiAssetPriceOracle.sol";

contract CheddaBaseTokenVault is Ownable, ERC4626 {

    // Basis used for all rate calculations. 100_000 == 100%
    uint32 constant public BASIS_POINTS = 100_000;

    struct VaultStats {
        uint256 liquidity;
        uint256 utilization;
        uint32 depositApr;
        uint32 borrowApr;
        uint32 rewardsApr;
    }
    enum CollateralType {
      ERC20,
      ERC721,
      ERC155
    }

    struct Collateral {
      address token;
      CollateralType cType;
      uint256 amount;
      uint256[] tokenIds;
    }

    // total amount deposited by liquidity providers
    uint256 public deposits;

    // total amount borrowed
    uint256 public borrowed;

    IPriceFeed public priceFeed;

    using SafeTransferLib for ERC20;

    // token address => is whitelisted
    mapping(address => bool) public collateralTokens;
    address[] public collateralTokenList;

    // Determines Loan to Value ratio for token
    mapping(address => uint256) public collateralFactor;

    // account => token => amount
    mapping(address => mapping(address => Collateral)) public accountCollateral;

    mapping(address => uint256) public accountBorrowed;


    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset, _name, _symbol) {}

    /*///////////////////////////////////////////////////////////////
                           ADMIN - WHITELIST TOKEN
    //////////////////////////////////////////////////////////////*/
    function whitelistToken(address token, bool isWhitelisted)
        public
        onlyOwner
    {
        collateralTokens[token] = isWhitelisted;
        _updateCollateralTokenList(token, isWhitelisted);
    }

    function assetBalance() public view returns (uint256 balance) {
        balance = deposits - borrowed;
    }

    function getVaultStats() public view returns (VaultStats memory) {
      VaultStats memory stats =  VaultStats({
        liquidity: totalAssets(),
        utilization: utilization(),
        depositApr: depositApr(),
        borrowApr: borrowApr(),
        rewardsApr: rewardsApr()
      });
      return stats;
    }

    /// Vault management
    function beforeWithdraw(uint256 amount, uint256 shares)
        internal
        virtual
        override
    {
        deposits -= amount;
    }

    function afterDeposit(uint256 amount, uint256 shares)
        internal
        virtual
        override
    {
        deposits += amount;
    }

    function totalAssets() public view override returns (uint256) {
        return deposits; // TODO: deposits + accrued interest
    }

    // rates
    function utilization() public view returns (uint32) {
        return uint32(borrowed * BASIS_POINTS / deposits);
    }

    function depositApr() public pure returns (uint32) {
        return 375 * 100_000 / 100; // TODO: make dynamic based on supply/demand. 3.75%
    }

    function borrowApr() public pure returns (uint32) {
      return  589 * 100_000 / 100; // TODO: make dynamic. 5.89%
    }

    function rewardsApr() public pure returns (uint32) {
      return  950 * 100_000 / 100; // 9.5%
    }

    /*///////////////////////////////////////////////////////////////
                           MANAGE COLLATERAL
    //////////////////////////////////////////////////////////////*/

    function addCollateral(address token, uint256 amount) public {
        // TODO: check if token address is ERC-20
        // Since token already whitelisted it must be one of the supported token types
        require(collateralTokens[token] == true, "CHVault: Not whitelisted");
        require(amount > 0, "CHVault: Invalid amount");
        address account = msg.sender;

        // add collateral to account
        if (accountHasCollateral(account, token)) {
            accountCollateral[account][token].amount += amount;
        } else {
            Collateral memory collateral = Collateral({
                token: token,
                cType: CollateralType.ERC20,
                amount: amount,
                tokenIds: new uint256[](0)
            });
            accountCollateral[account][token] = collateral;
        }
        ERC20(token).transferFrom(account, address(this), amount);
    }

    function removeCollateral(address token, uint256 amount) public {
        address account = msg.sender;
        require(amount > 0, "CHVault: Invalid amount");
        require(accountCollateralCount(account, token) >= amount, "CHVault: INSUF Coll");
        accountCollateral[account][token].amount -= amount;
        ERC20(token).transfer(msg.sender, amount);
    }

    function addCollateral721(address token, uint256[] memory tokenIds) public {
        require(collateralTokens[token] == true, "CHVault: Not whitelisted");
        require(tokenIds.length > 0, "CHVault: Empty token list");

        address account = msg.sender;

        if (accountHasCollateral(account, token)) {
            Collateral storage collateral = accountCollateral[account][token];
            for (uint256 i = 0; i < tokenIds.length; i++) {
                for (uint256 j = 0; j < collateral.tokenIds.length; j++) {
                    if (tokenIds[i] == collateral.tokenIds[j]) {
                        revert("CHVault: Already Added");
                    }
                }
                collateral.tokenIds.push(tokenIds[i]);
            }

            accountCollateral[account][token].amount += tokenIds.length;
            require(collateral.tokenIds.length == collateral.amount, "CHVault: Incorrect token amount");
        } else {
            Collateral memory collateral = Collateral({
                token: token,
                cType: CollateralType.ERC721,
                amount: tokenIds.length,
                tokenIds: tokenIds
            });
            accountCollateral[account][token] = collateral;
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
          IERC721(token).transferFrom(account, address(this), tokenIds[i]);
        }
    }

    function accountHasCollateral(address account, address collateral) public view returns (bool) {
      return accountCollateral[account][collateral].token != address(0);
    }

    function accountCollateralCount(address account, address collateral) public view returns (uint256) {
        return accountCollateral[account][collateral].amount;
    }

    // borrows a loan
    function take(uint256 amount) public {
        address account = msg.sender;
        // check collateral value > ltv (amount)
        uint256 collateralValue = totalAccountCollateralValue(account);
        uint borrowedValue = 0;

        // require collateralFactor * collateral >= amount + borrowed
        // require(
        //     accountBorrowed[account] + amount <= accountCollateral[account],
        //     "Insufficient collateral"
        // );
        // borrowed += amount;
        // accountBorrowed[account] += amount;
        // asset.safeTransferFrom(address(this), account, amount);
    }

    // repays a loan
    function put(uint256 amount) public {
        address account = address(msg.sender);
        borrowed -= amount;
        accountBorrowed[account] -= amount;
        asset.safeTransferFrom(msg.sender, address(this), amount);
    }

    function totalAccountCollateralValue(address account)
        public
        view
        returns (uint256)
    {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < collateralTokenList.length; i++) {
            address token = collateralTokenList[i];
            Collateral memory collateral = accountCollateral[account][token];
            if (accountHasCollateral(account, token)) {
                uint256 amount = collateral.amount;
                int collateralValue = priceFeed.getLatestPrice(token, amount);
                if (collateralValue > 0) {
                    totalValue += uint256(collateralValue);
                }
            }
        }

        return totalValue;
    }

    function _updateCollateralTokenList(address token, bool add) internal {
        if (add) {
            for (uint256 i = 0; i < collateralTokenList.length; i++) {
                if (collateralTokenList[i] == token) {
                    return; // already added
                }
            }
            collateralTokenList.push(token);
        } else {
            for (uint256 i = 0; i < collateralTokenList.length; i++) {
                if (collateralTokenList[i] == token) {
                    collateralTokenList[i] = collateralTokenList[
                        collateralTokenList.length - 1
                    ];
                    collateralTokenList.pop();
                }
            }
        }
    }
}
