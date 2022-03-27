//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import { ERC20 } from "./ERC20.sol";
import { ERC4626 } from "./ERC4626.sol";
import { FixedPointMathLib } from "../lib/FixedPointMathLib.sol";

interface ICheddaDebtToken {
    function createDebt(uint256 amount, address account) external returns (uint256);
    function repayShare(uint256 shares, address account) external returns (uint256);
    function repayAmount(uint256 amount, address account) external returns (uint256);
    function totalBorrowed() external view returns (uint256);
    function amountForShares(uint256 shares) external view returns (uint256);
    function sharesForAmount(uint256 amount) external view returns (uint256);
    function accountShare(address account) external view returns (uint256);
}

/// @title CheddaDebtToken
/// @notice Token representing amount borrowed and pending interest on this debt.
contract CheddaDebtToken is ERC20, ICheddaDebtToken {

    using FixedPointMathLib for uint256;

    event DebtCreated(address indexed account, uint256 amount, uint256 shares);
    event DebtRepaid(address indexed account, uint256 amount, uint256 shares);

    uint256 public constant BASE_RATE = 1e18;
    uint64 public constant STARTING_INTEREST_RATE_PER_SECOND = 317097919; // approx 1% APR
    uint64 public constant ONE_PERCENT = 1e18 / 100;
    uint64 public constant PER_SECOND = ONE_PERCENT / 365 / 86400;
    uint256 internal immutable ONE;

    uint256 private _lastAccrual;
    uint256 private _interestPerSecond;
    uint256 private _variableTotalDebt;
    address public vault;
    address public asset;

    modifier onlyVault() {
        // TODO: uncomment after testing.
        // require(msg.sender == vault, "CHDebt: Only vault");
        _;
    }

    /// @notice Creates a debt token. 
    /// @param _asset the asset being borrowed.
    /// @param _vault the Chedda vault this asset is being borrowed from.
    constructor(ERC20 _asset, address _vault)
    ERC20(
    string(abi.encodePacked("CHEDDA Debt-", _asset.name())),
    string(abi.encodePacked("cd-", _asset.symbol())),
    _asset.decimals()
    ) {
        ONE = 10**decimals; // >77 decimals is unlikely.
        asset = address(_asset);
        vault = _vault;
    }

    function accountShare(address account) external view returns (uint256) {
        return balanceOf[account];
    }


    /*///////////////////////////////////////////////////////////////
                    ICheddaDebtToken implementation
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the total principal amount of debt tracked.
    /// @dev This does not include any future interest payments.
    /// @return borrowed Total amount of debt (principal) tracked.
    function totalBorrowed() external view returns (uint256 borrowed) {
        borrowed = totalAssets();
    }

    /// @notice records the creation of debt. `account` borrowed `amount` of underlying token.
    /// @dev Explain to a developer any extra details
    /// @param amount The amount borrowed
    /// @param account The account doing the borrowing
    /// @return shares The number of tokens minted to track this debt + future interest payments.
    function createDebt(uint256 amount, address account) external onlyVault returns (uint256 shares) {
        // accrue must be called before anything else.
        _accrue();
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(amount)) != 0, "ZERO_SHARES");

        _variableTotalDebt += amount;

        _mint(account, shares);

        emit DebtCreated(account, amount, shares);

        afterDeposit(amount, shares);
    }

    /// @notice records the repayment of debt. `account` borrowed `shares` portion of outstanding debt.
    /// @dev Explain to a developer any extra details
    /// @param share The portion of debt to repay
    /// @param account The account repaying
    /// @return amount The amount of debt repaid
    function repayShare(uint256 share, address account) external onlyVault returns (uint256 amount) {
        _accrue();

        // Check for rounding error since we round down in previewRedeem.
        require((amount = previewRedeem(share)) != 0, "ZERO_ASSETS");

        beforeWithdraw(amount, share);

        _variableTotalDebt -= amount;
        _burn(account, share);

        emit DebtRepaid(account, amount, share);
    }

    function repayAmount(uint256 amount, address account) external onlyVault returns (uint256 shares) {
       shares = previewWithdraw(amount); // No need to check for rounding error, previewWithdraw rounds up.

        beforeWithdraw(amount, shares);

        _variableTotalDebt -= amount;
        _burn(account, shares);

        emit DebtRepaid(account, amount, shares);
    }

    /// @notice The amount of underlying token covered by this amount of debt token.
    /// @param share the number of shares of debt token.
    /// @return amount the amount of underlying token covered.
    function amountForShares(uint256 share) external view returns (uint256 amount) {
        amount = previewRedeem(share);
    }

    /// @notice The share of debt token representing a given amount of underlying token.
    /// @param amount The amount of underlying token to check.
    /// @return share the amount of debt token that covers this amount of debt.
    function sharesForAmount(uint256 amount) external view returns (uint256 share) {
        share = previewWithdraw(amount);
    }
    
    /*///////////////////////////////////////////////////////////////
                           ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns total owed (amount borrowed + outstanding interest payments).
    /// @return totalDebt Total outstanding debt
    function totalAssets() public view returns (uint256 totalDebt) {
        totalDebt = _variableTotalDebt;
    }

    function assetsOf(address user) public view virtual returns (uint256) {
        return previewRedeem(balanceOf[user]);
    }

    function assetsPerShare() public view virtual returns (uint256) {
        return previewRedeem(ONE);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 amount) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? amount : amount.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 amount) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? amount : amount.mulDivUp(supply, totalAssets());
    }

    function accrue() external {
        _accrue();
    }

    function beforeWithdraw(uint256 amount, uint256 shares) internal virtual {
        // silence unused variable warnings
        amount;
        shares;
        _accrue();
    }

    function afterDeposit(uint256 amount, uint256 shares) internal virtual {
        // silence unused variable warnings
        amount;
        shares;
        _accrue();
    }

    function _accrue() internal {
        uint256 timestamp =  _timestamp();
         uint256 elapsedTime = timestamp - _lastAccrual;
        if (elapsedTime == 0) {
            return;
        }
        if (_interestPerSecond == 0) {
            _interestPerSecond = STARTING_INTEREST_RATE_PER_SECOND;
        } else {
            _interestPerSecond = _calculateNewBorrowRate();
        }

        _lastAccrual = timestamp;
        uint256 interest = _variableTotalDebt.mulWadUp(_interestPerSecond * elapsedTime);
        _variableTotalDebt += interest;
    }

    // Debt tokens are non-transferrable
    function transfer(address to, uint256 amount) public override returns (bool rv) {
        to;
        amount;
        rv = false;
        revert("CHDebt: Non-transferrable");
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool rv) {
        from;
        to;
        amount;
        rv = false;
        revert("CHDebt: Non-transferrable");
    }

    function _timestamp() private view returns (uint256) {
        return block.timestamp;
    }

    function _calculateNewBorrowRate() private pure returns (uint256) {
        return PER_SECOND; // TODO: update based on demand/supply
    }

}
