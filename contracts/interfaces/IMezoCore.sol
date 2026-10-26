// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

interface IMUSD {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IPriceFeed {
    function fetchPrice() external returns (uint256);
}

interface IBorrowerOperations {
    function openTrove(
        uint256 _debtAmount,
        address _upperHint,
        address _lowerHint
    ) external payable;

    function adjustTrove(
        uint256 _collWithdrawal,
        uint256 _debtChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) external payable;
}

interface ITroveManager {
    function getCurrentICR(address _borrower, uint256 _price) external view returns (uint256);
    function getTroveStatus(address _borrower) external view returns (uint256);
}

interface IStabilityPool {
    function provideToSP(uint256 _amount) external;
    function withdrawFromSP(uint256 _amount) external;
    function getCompoundedMUSDDeposit(address _depositor) external view returns (uint256);
}

interface IMezoCreditVault {
    function pullAndRouteMUSD(address owner, address merchant, uint256 musdAmount) external;
}

struct CreditPosition {
    uint256 collateralBtc;
    uint256 mintedMusd;
    uint256 availableCreditMusd;
    bool troveActive;
}

struct AgentAllowance {
    address treasuryOwner;
    uint128 dailyLimitMusd;
    uint128 spentTodayMusd;
    uint64 currentDayEpoch;
    bool active;
}

struct X402Invoice {
    bytes32 invoiceId;
    address merchant;
    uint256 amountMusd;
    uint64 expiryTimestamp;
    string resourceUri;
}

error ZeroValueDisallowed();
error InsufficientCreditBalance(uint256 requested, uint256 available);
error CollateralRatioBelowSafeFloor(uint256 projectedICR, uint256 minimumSafeICR);
error UnauthorizedRouterCaller(address caller);
error UnauthorizedAgent(address agent);
error DailySpendLimitExceeded(uint256 requested, uint256 remainingAllowance);
error InvoiceExpiredOrReplayed(bytes32 invoiceId);