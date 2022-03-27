//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC4626 } from "../tokens/ERC4626.sol";
import { ERC20 } from "../tokens/ERC20.sol";
import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { FixedPointMathLib } from "../lib/FixedPointMathLib.sol";
import { ICheddaDebtToken, CheddaDebtToken } from "../tokens/CheddaDebtToken.sol";
import { IPriceFeed, MultiAssetPriceOracle } from "../oracle/MultiAssetPriceOracle.sol";
import { IInterestRateModel } from "./InterestRateModel.sol";

/// @title CheddaBaseTokenVault
/// @notice Represents a lending pool on the Chedda platform.
contract CheddaBaseTokenVault is Ownable, ERC4626 {

    struct VaultStats {
        uint256 liquidity;
        uint256 utilization;
        uint128 depositApr;
        uint128 borrowApr;
        uint128 rewardsApr;
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

    struct CollateralValue {
        address token;
        uint256 amount;
        int256 value;
    }

    // Events
    event OnTokenWhitelisted(address indexed token, address indexed user);
    event OnCollateralAdded(address indexed token, address indexed account, CollateralType ofType, uint256 amount);
    event OnCollateralRemoved(address indexed token, address indexed account, CollateralType ofType, uint256 amount);
    event OnLoanOpened(address account, uint256 amount);
    event OnLoanRepaid(address account, uint256 amount);

    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    
    // total amount deposited by liquidity providers
    uint256 public deposits;

    IPriceFeed public priceFeed;

    uint256 constant public PECISION = 1e18;
    uint256 constant public MAX_LTV = 7 * 1e17; // 70%
    int256 public borrowFee = 3 * 1e15; // 0.3%;

    // token address => is whitelisted
    mapping(address => bool) public collateralTokens;

    ICheddaDebtToken public debtToken;
    IInterestRateModel public interestRateModel;

    // use mapping to support multi-asset lending pool
    // token address => Debt token
    // mapping(address => address) public debtTokens;

    // list of tokens that can be used as collateral
    address[] public collateralTokenList;

    // Determines Loan to Value ratio for token
    mapping(address => uint256) public collateralFactor;

    // account => token => amount
    mapping(address => mapping(address => Collateral)) public accountCollateral;
    
    // token address => Collateral amount
    mapping(address => uint256) public tokenCollateral;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset, _name, _symbol) {
        debtToken = new CheddaDebtToken(asset, address(this));
    }

    /*///////////////////////////////////////////////////////////////
                           ADMIN - WHITELIST TOKEN
    //////////////////////////////////////////////////////////////*/

    /// @notice Whitelist a token as collateral
    /// @dev Only tokens previously whitelisted can be added as collateral.
    /// @param token token address
    /// @param isWhitelisted If true, allow this token as collateral. If false, this token
    /// can no longer be used as collateral
    function whitelistToken(address token, bool isWhitelisted)
        external
        onlyOwner
    {
        collateralTokens[token] = isWhitelisted;
        _updateCollateralTokenList(token, isWhitelisted);

        emit OnTokenWhitelisted(token, msg.sender);
    }

    /// @notice Total assets deposited as liquidity in this vault - amount borrowed
    /// @dev this represents available liquidity in this vault
    /// @return balance deposits - borrowed
    function assetBalance() public view returns (uint256 balance) {
        balance = deposits - totalBorrowed();
    }

    function getVaultStats() external view returns (VaultStats memory) {
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
        return deposits;
    }

    // rates
    function utilization() public view returns (uint256 utilized) {
        utilized  = totalBorrowed().divWadUp(totalAssets());
    }

    function depositApr() public view returns (uint128) {
        return interestRateModel.depositAPR();
    }

    function borrowApr() public view returns (uint128) {
      return  interestRateModel.borrowAPR();
    }

    function rewardsApr() public pure returns (uint128) {
      return  950 * 100_000 / 100; // 9.5% // TODO: dynamic rewards
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

        tokenCollateral[token] += amount;

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

        ERC20(token).safeTransferFrom(account, address(this), amount);

        emit OnCollateralAdded(token, account, CollateralType.ERC20, amount);
    }

    function removeCollateral(address token, uint256 amount) public {
        address account = msg.sender;
        require(amount > 0, "CHVault: Invalid amount");
        require(accountCollateralCount(account, token) >= amount, "CHVault: INSUF Coll");

        tokenCollateral[token] -= amount;

        if (accountCollateralCount(account, token) == amount) {
            delete accountCollateral[account][token];
        } else {
            accountCollateral[account][token].amount -= amount;
        }

        if (accountPendingAmount(account) > totalAccountCollateralValue(account)) {
            revert("CHVault: Not enough collateral");
        }

        ERC20(token).safeTransfer(msg.sender, amount);

        emit OnCollateralRemoved(token, account, CollateralType.ERC20, amount);
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

        emit OnCollateralAdded(token, account, CollateralType.ERC721, tokenIds.length);
    }

    function removeCollateral721(address token, uint256[] memory tokenIds) public {
        require(collateralTokens[token] == true, "CHVault: Not whitelisted");
        require(tokenIds.length > 0, "CHVault: Empty token list");
        address account = msg.sender;
        Collateral storage collateral = accountCollateral[account][token];
        require(tokenIds.length >= collateral.amount, "CHVault: Invalid token IDs");
        uint8 matchesFound = 0;

        // make sure account is the owner of all the tokens in `tokenIds`
        for (uint256 i = 0; i < collateral.tokenIds.length; i++) {
            for (uint256 j = 0; j < tokenIds.length; j++) {
               if (collateral.tokenIds[i] == tokenIds[j]) {
                    IERC721(token).safeTransferFrom(address(this), account, tokenIds[j]);
                    matchesFound += 1;
               } 
            }
        }

        // revert if any tokenIds are invalid
        require(matchesFound == tokenIds.length, "CHVault: Invalid token ID");
        accountCollateral[account][token].amount -= tokenIds.length;

        if (accountPendingAmount(account) > totalAccountCollateralValue(account)) {
            revert("CHVault: Not enough collateral");
        }

        // transfer back collateral
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(token).safeTransferFrom(address(this), account, tokenIds[i]);
        }

        emit OnCollateralRemoved(token, account, CollateralType.ERC721, tokenIds.length);
    } 

    function accountHasCollateral(address account, address collateral) public view returns (bool) {
      return accountCollateral[account][collateral].token != address(0);
    }

    function accountCollateralCount(address account, address collateral) public view returns (uint256) {
        return accountCollateral[account][collateral].amount;
    }

    function collateralAmounts() public view returns (CollateralValue[] memory) {
        CollateralValue[] memory collateralValues = new CollateralValue[](collateralTokenList.length);
        for (uint256 i = 0; i < collateralTokenList.length; i++) {
            address token = collateralTokenList[i];
            uint256 collateralAmount = tokenCollateral[token];
            int256 price = priceFeed.readPrice(token, 0);
            int256 value = price * int256(collateralAmount);
            CollateralValue memory cValue = CollateralValue({
                token: token,
                amount: collateralAmount,
                value: value
            });
            collateralValues[i] = cValue;
        }
        return collateralValues;
    }

    /// @notice Get the current value of users collateral.
    /// @param account Account to return collateral value for
    /// @return current collateral value of users account
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
                uint256 collateralValue = _getTokenValue(token, amount);
                if (collateralValue > 0) {
                    totalValue += uint256(collateralValue);
                }
            }
        }

        return totalValue;
    }

    /// @notice Updates the list of allowable collateral tokens.
    /// @param token address of token to add or remove.
    /// @param add if `true` add the `token` to whitelist, else remove the token.
    /// adding a token which is already in the list has no effect. 
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

    /*///////////////////////////////////////////////////////////////
                        borrow/repay logic
    //////////////////////////////////////////////////////////////*/

    /// borrows a loan
    /// @notice Takes out a loan
    /// @dev The max amount a user can borrow must be less than the value of their collateral weighted
    /// against the loan to value ratio of that colalteral.
    /// @param amount The amount to borrow
    function take(uint256 amount) public {
        address account = msg.sender;
        // check collateral value > ltv (amount)
        _validateBorrow(account, amount);

        debtToken.createDebt(amount, account);
        asset.safeTransferFrom(address(this), account, amount);
        emit OnLoanOpened(account, amount);
    }

    // repays a loan
    /// @notice Repays a part or all of a loan.
    /// @param amount amount to repay. Must be > 0 and <= amount borrowed by sender
    function putAmount(uint256 amount) public {
        address account = address(msg.sender);
        require(amount != 0, "CHVault: Invalid amount");
        require(amount <= accountPendingAmount(account), "CHVault: amount too high");
        asset.safeTransferFrom(msg.sender, address(this), amount);
        debtToken.repayAmount(amount, account);

        emit OnLoanRepaid(account, amount);
    }

    // repays a loan
    /// @notice Repays a part or all of a loan.
    /// @param shares The share of debt token to repay.
    function putShares(uint256 shares) public {
        address account = address(msg.sender);
        require(shares != 0, "CHVault: Invalid amount");
        require(shares <= debtToken.accountShare(account), "CHVault: shares too high");
        
        uint256 amount = debtToken.amountForShares(shares);
        asset.safeTransferFrom(msg.sender, address(this), amount);
        debtToken.repayShare(shares, account);

        emit OnLoanRepaid(account, amount);
    }

    function totalBorrowed() public view returns (uint256 amount) {
        amount = debtToken.totalBorrowed();
    }

    function accountPendingAmount(address account) public view returns (uint256 borrowed) {
        uint256 shares = debtToken.accountShare(account);
        borrowed = debtToken.amountForShares(shares);
    }

    function _getTokenValue(address token, uint256 amount) internal view returns (uint256) {
        int256 price = priceFeed.readPrice(token, 0);
        require(price > 0, "CHVault: Invalid price");
        return uint256(price) * amount;
    }
    /// @notice Checks if account is currently solvent.
    /// @dev TODO: implement LTV rules 
    /// @param account The account to check
    /// @return `true` is account is currently solvent, `false` otherwise.
    function _isSolvent(address account) internal view returns (bool) {
        // TODO: check value of collateral against amount borrowed.
        // Also apply LTV rules. 
        return accountPendingAmount(account) < totalAccountCollateralValue(account);
    }

    function _validateBorrow(address account, uint256 amount) internal view {
        require (amount != 0, "Invalid amount");
        require (account != address(0), "Invalid address");
        uint256 maxLTV = 10000 * 0.75;
        uint256 collateralValue = totalAccountCollateralValue(account);
        uint256 newTotalBorrow = accountPendingAmount(account) + amount;
        require (newTotalBorrow < collateralValue * maxLTV, "Not enough collateral");
    }
}
