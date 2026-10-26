import { NextRequest, NextResponse } from "next/server";
import { X402ChallengeBuilder, X402OnchainSettler } from "../../../services/X402CreditFacilitator";
import { MEZO_TESTNET_CONTRACTS } from "../../../config/mezoTestnet";

const challengeBuilder = new X402ChallengeBuilder();
const settler = new X402OnchainSettler();

const DEFAULT_MERCHANT = "0x78A2Ac528DD4dCa969242A04Ca909ec084B50813" as const;
const PRICE_WEI = 500_000_000_000_000_000n; // 0.50 MUSD (18 decimals)

export async function GET(req: NextRequest) {
  const paymentHeader = req.headers.get("x-payment");

  if (!paymentHeader) {
    const challenge = challengeBuilder.buildPaymentHeader(
      DEFAULT_MERCHANT,
      PRICE_WEI,
      req.nextUrl.pathname
    );

    return NextResponse.json(
      {
        status: 402,
        message: "HTTP 402 Payment Required — Settle via Mezo X402SettlementRouter",
        router: MEZO_TESTNET_CONTRACTS.X402_SETTLEMENT_ROUTER,
        vault: MEZO_TESTNET_CONTRACTS.MEZO_CREDIT_VAULT,
        challenge,
      },
      {
        status: 402,
        headers: {
          "X-Payment-Required": Buffer.from(JSON.stringify(challenge)).toString("base64"),
        },
      }
    );
  }

  try {
    const { txHash, invoiceId } = challengeBuilder.parsePaymentReceipt(paymentHeader);
    const verified = await settler.verifyReceiptOnMezo(txHash);

    if (!verified) {
      return NextResponse.json(
        { error: "Settlement transaction not confirmed on Mezo Testnet", txHash, invoiceId },
        { status: 402 }
      );
    }

    return NextResponse.json({
      status: 200,
      settled: true,
      network: MEZO_TESTNET_CONTRACTS.CAIP2_NETWORK,
      router: MEZO_TESTNET_CONTRACTS.X402_SETTLEMENT_ROUTER,
      txHash,
      invoiceId,
      data: {
        btcOraclePriceUsd: 100000,
        mezoStabilityPoolYieldApr: "6.85%",
      },
    });
  } catch (err) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "Invalid X-PAYMENT header" },
      { status: 400 }
    );
  }
}
