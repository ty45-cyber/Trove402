// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {
    IMezoCreditVault,
    AgentAllowance,
    X402Invoice,
    ZeroValueDisallowed,
    UnauthorizedAgent,
    DailySpendLimitExceeded,
    InvoiceExpiredOrReplayed
} from "./interfaces/IMezoCore.sol";

contract X402SettlementRouter {
    IMezoCreditVault public immutable creditVault;

    mapping(address => AgentAllowance) public agentPolicies;
    mapping(bytes32 => bool) public settledInvoices;

    event AgentPolicyConfigured(address indexed treasuryOwner, address indexed agent, uint128 dailyLimitMusd, bool active);
    event X402InvoiceSettled(
        bytes32 indexed invoiceId,
        address indexed agent,
        address indexed merchant,
        uint256 amountMusd,
        string resourceUri
    );

    constructor(address _creditVault) {
        if (_creditVault == address(0)) revert ZeroValueDisallowed();
        creditVault = IMezoCreditVault(_creditVault);
    }

    /**
     * @notice Registers or revokes an autonomous AI agent's daily MUSD spending limit against the caller's vault.
     */
    function configureAgentPolicy(
        address agent,
        uint128 dailyLimitMusd,
        bool active
    ) external {
        if (agent == address(0) || (active && dailyLimitMusd == 0)) revert ZeroValueDisallowed();

        uint64 currentDay = uint64(block.timestamp / 1 days);
        agentPolicies[agent] = AgentAllowance({
            treasuryOwner: msg.sender,
            dailyLimitMusd: dailyLimitMusd,
            spentTodayMusd: 0,
            currentDayEpoch: currentDay,
            active: active
        });

        emit AgentPolicyConfigured(msg.sender, agent, dailyLimitMusd, active);
    }

    /**
     * @notice Atomically verifies an HTTP 402 challenge, enforces daily spend caps, and routes MUSD from StabilityPool.
     */
    function settleX402Invoice(X402Invoice calldata invoice) external {
        if (
            invoice.invoiceId == bytes32(0) ||
            invoice.merchant == address(0) ||
            invoice.amountMusd == 0
        ) revert ZeroValueDisallowed();

        if (settledInvoices[invoice.invoiceId] || block.timestamp > invoice.expiryTimestamp) {
            revert InvoiceExpiredOrReplayed(invoice.invoiceId);
        }

        AgentAllowance storage policy = agentPolicies[msg.sender];
        if (!policy.active || policy.treasuryOwner == address(0)) {
            revert UnauthorizedAgent(msg.sender);
        }

        uint64 todayEpoch = uint64(block.timestamp / 1 days);
        if (policy.currentDayEpoch < todayEpoch) {
            policy.currentDayEpoch = todayEpoch;
            policy.spentTodayMusd = 0;
        }

        uint256 newDailyTotal = uint256(policy.spentTodayMusd) + invoice.amountMusd;
        if (newDailyTotal > uint256(policy.dailyLimitMusd)) {
            revert DailySpendLimitExceeded(
                invoice.amountMusd,
                uint256(policy.dailyLimitMusd) - uint256(policy.spentTodayMusd)
            );
        }

        settledInvoices[invoice.invoiceId] = true;
        policy.spentTodayMusd = uint128(newDailyTotal);

        creditVault.pullAndRouteMUSD(policy.treasuryOwner, invoice.merchant, invoice.amountMusd);

        emit X402InvoiceSettled(
            invoice.invoiceId,
            msg.sender,
            invoice.merchant,
            invoice.amountMusd,
            invoice.resourceUri
        );
    }
}