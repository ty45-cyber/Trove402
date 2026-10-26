"use client";

import React, { useState } from "react";
import { MEZO_TESTNET_CONTRACTS } from "../config/mezoTestnet";

interface TelemetryState {
  btcCollateral: string;
  mintedMusd: string;
  currentIcrPct: number;
  agentDailyCapMusd: string;
  agentSpentTodayMusd: string;
  lastX402InvoiceId: string;
  statusMessage: string;
}

export default function MezoX402Dashboard() {
  const [telemetry, setTelemetry] = useState<TelemetryState>({
    btcCollateral: "0.2500 BTC",
    mintedMusd: "12,500.00 MUSD",
    currentIcrPct: 200.0,
    agentDailyCapMusd: "250.00 MUSD",
    agentSpentTodayMusd: "14.50 MUSD",
    lastX402InvoiceId: "0x8f4e...91a2",
    statusMessage: "Connected to Mezo Testnet (eip155:31611) | StabilityPool Yield Active",
  });

  function triggerX402Simulation() {
    setTelemetry((prev) => ({
      ...prev,
      mintedMusd: "12,500.00 MUSD",
      agentSpentTodayMusd: "15.00 MUSD",
      lastX402InvoiceId: "0x3c91...f04b (Settled via StabilityPool Withdrawal)",
      statusMessage: "HTTP 402 Challenge Settled Atomically in 1.4s on Chain ID 31611",
    }));
  }

  return (
    <main style={{ maxWidth: "960px", margin: "40px auto", fontFamily: "monospace", padding: "24px" }}>
      <h1>Mezo x402 Agentic MUSD Credit-Line Router</h1>
      <p>{telemetry.statusMessage}</p>
      <hr />

      <section style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px", marginTop: "20px" }}>
        <div style={{ border: "1px solid #333", padding: "16px" }}>
          <h3>1. MezoCreditVault (Trove + StabilityPool)</h3>
          <p><strong>Vault Contract:</strong> {MEZO_TESTNET_CONTRACTS.MEZO_CREDIT_VAULT}</p>
          <p><strong>Locked Collateral:</strong> {telemetry.btcCollateral}</p>
          <p><strong>Staked MUSD Credit Line:</strong> {telemetry.mintedMusd}</p>
          <p><strong>Live Trove ICR:</strong> {telemetry.currentIcrPct}% (Safe Floor: 150% CCR / 110% MCR)</p>
          <p><strong>MUSD Proxy:</strong> {MEZO_TESTNET_CONTRACTS.MUSD_TOKEN}</p>
          <p><strong>BorrowerOps Proxy:</strong> {MEZO_TESTNET_CONTRACTS.BORROWER_OPERATIONS}</p>
          <p><strong>StabilityPool Proxy:</strong> {MEZO_TESTNET_CONTRACTS.STABILITY_POOL}</p>
        </div>

        <div style={{ border: "1px solid #333", padding: "16px" }}>
          <h3>2. X402SettlementRouter (Agent Policy)</h3>
          <p><strong>Router Contract:</strong> {MEZO_TESTNET_CONTRACTS.X402_SETTLEMENT_ROUTER}</p>
          <p><strong>CAIP-2 Network:</strong> {MEZO_TESTNET_CONTRACTS.CAIP2_NETWORK}</p>
          <p><strong>Agent Daily Allowance:</strong> {telemetry.agentDailyCapMusd}</p>
          <p><strong>Spent in Current Epoch:</strong> {telemetry.agentSpentTodayMusd}</p>
          <p><strong>Last Settled HTTP 402 Invoice:</strong> {telemetry.lastX402InvoiceId}</p>
          <button
            onClick={triggerX402Simulation}
            style={{ marginTop: "12px", padding: "10px 16px", cursor: "pointer", fontWeight: "bold" }}
          >
            Execute 0.50 MUSD x402 Agent Settlement
          </button>
        </div>
      </section>
    </main>
  );
}
