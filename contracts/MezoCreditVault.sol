// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {
    IMUSD,
    IPriceFeed,
    IBorrowerOperations,
    IStabilityPool,
    CreditPosition,
    ZeroValueDisallowed,
    InsufficientCreditBalance,
    CollateralRatioBelowSafeFloor,
    UnauthorizedRouterCaller
} from "./interfaces/IMezoCore.sol";

contract MezoCreditVault {
    uint256 public constant SAFE_ICR_FLOOR = 1.50e18; // 150% CCR safety floor (MCR is 110%)

    IMUSD public immutable musd;
    IPriceFeed public immutable priceFeed;
    IBorrowerOperations public immutable borrowerOps;
    IStabilityPool public immutable stabilityPool;
    address public immutable settlementRouter;

    mapping(address => CreditPosition) public positions;
    bool public vaultTroveInitialized;

    event CreditLineUpdated(address indexed owner, uint256 btcAdded, uint256 musdMinted, uint256 projectedICR);
    event CreditRoutedToMerchant(address indexed owner, address indexed merchant, uint256 musdAmount);

    constructor(
        address _musd,
        address _priceFeed,
        address _borrowerOps,
        address _stabilityPool,
        address _settlementRouter
    ) {
        if (
            _musd == address(0) ||
            _priceFeed == address(0) ||
            _borrowerOps == address(0) ||
            _stabilityPool == address(0) ||
            _settlementRouter == address(0)
        ) revert ZeroValueDisallowed();

        musd = IMUSD(_musd);
        priceFeed = IPriceFeed(_priceFeed);
        borrowerOps = IBorrowerOperations(_borrowerOps);
        stabilityPool = IStabilityPool(_stabilityPool);
        settlementRouter = _settlementRouter;
    }

    /**
     * @notice Locks native BTC into a Mezo Trove, mints 1% fixed-rate MUSD, and stakes it in StabilityPool.
     */
    function openOrExpandCreditLine(
        uint256 mintMusdAmount,
        address upperHint,
        address lowerHint
    ) external payable {
        if (msg.value == 0 || mintMusdAmount == 0) revert ZeroValueDisallowed();

        CreditPosition storage pos = positions[msg.sender];
        uint256 newCollateral = pos.collateralBtc + msg.value;
        uint256 newDebt = pos.mintedMusd + mintMusdAmount;

        uint256 btcPrice = priceFeed.fetchPrice();
        uint256 projectedICR = (newCollateral * btcPrice) / newDebt;
        if (projectedICR < SAFE_ICR_FLOOR) {
            revert CollateralRatioBelowSafeFloor(projectedICR, SAFE_ICR_FLOOR);
        }

        pos.collateralBtc = newCollateral;
        pos.mintedMusd = newDebt;
        pos.availableCreditMusd += mintMusdAmount;
        pos.troveActive = true;

        if (!vaultTroveInitialized) {
            vaultTroveInitialized = true;
            borrowerOps.openTrove{value: msg.value}(mintMusdAmount, upperHint, lowerHint);
        } else {
            borrowerOps.adjustTrove{value: msg.value}(0, mintMusdAmount, true, upperHint, lowerHint);
        }

        musd.approve(address(stabilityPool), mintMusdAmount);
        stabilityPool.provideToSP(mintMusdAmount);

        emit CreditLineUpdated(msg.sender, msg.value, mintMusdAmount, projectedICR);
    }

    /**
     * @notice Called exclusively by X402SettlementRouter to withdraw MUSD from StabilityPool and pay a merchant.
     */
    function pullAndRouteMUSD(
        address owner,
        address merchant,
        uint256 musdAmount
    ) external {
        if (msg.sender != settlementRouter) revert UnauthorizedRouterCaller(msg.sender);
        if (musdAmount == 0 || merchant == address(0)) revert ZeroValueDisallowed();

        CreditPosition storage pos = positions[owner];
        if (pos.availableCreditMusd < musdAmount) {
            revert InsufficientCreditBalance(musdAmount, pos.availableCreditMusd);
        }

        pos.availableCreditMusd -= musdAmount;
        stabilityPool.withdrawFromSP(musdAmount);

        bool transferred = musd.transfer(merchant, musdAmount);
        if (!transferred) revert ZeroValueDisallowed();

        emit CreditRoutedToMerchant(owner, merchant, musdAmount);
    }
}