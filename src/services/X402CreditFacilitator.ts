import { createPublicClient, createWalletClient, http, keccak256, toHex, type Address, type Hex } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { mezoTestnet, MEZO_TESTNET_CONTRACTS, ROUTER_ABI } from "../config/mezoTestnet";

export interface X402PaymentChallenge {
  scheme: "exact";
  network: typeof MEZO_TESTNET_CONTRACTS.CAIP2_NETWORK;
  asset: Address;
  payTo: Address;
  maxAmountRequired: string;
  resource: string;
  invoiceId: Hex;
  expiryTimestamp: number;
}

export class X402ChallengeBuilder {
  /**
   * Generates a compliant HTTP 402 Payment-Required payload for Mezo Testnet MUSD (eip155:31611).
   */
  public buildPaymentHeader(merchant: Address, amountWei: bigint, resourceUri: string): X402PaymentChallenge {
    const expiryTimestamp = Math.floor(Date.now() / 1000) + 300;
    const invoiceId = keccak256(toHex(`${merchant}:${amountWei.toString()}:${resourceUri}:${expiryTimestamp}`));

    return {
      scheme: "exact",
      network: MEZO_TESTNET_CONTRACTS.CAIP2_NETWORK,
      asset: MEZO_TESTNET_CONTRACTS.MUSD_TOKEN,
      payTo: merchant,
      maxAmountRequired: amountWei.toString(),
      resource: resourceUri,
      invoiceId,
      expiryTimestamp,
    };
  }

  /**
   * Decodes and validates a base64 X-PAYMENT header submitted by an autonomous agent.
   */
  public parsePaymentReceipt(base64Header: string): { txHash: Hex; invoiceId: Hex } {
    const decoded = JSON.parse(Buffer.from(base64Header, "base64").toString("utf-8"));
    if (!decoded.txHash || !decoded.invoiceId) {
      throw new Error("Malformed X-PAYMENT header payload");
    }
    return { txHash: decoded.txHash as Hex, invoiceId: decoded.invoiceId as Hex };
  }
}

export class X402OnchainSettler {
  private readonly publicClient = createPublicClient({
    chain: mezoTestnet,
    transport: http(),
  });

  /**
   * Called by the AI Agent runtime upon receiving HTTP 402 to atomically settle MUSD from the Credit Vault.
   */
  public async executeAgentSettlement(
    agentPrivateKey: Hex,
    routerAddress: Address,
    challenge: X402PaymentChallenge
  ): Promise<Hex> {
    const account = privateKeyToAccount(agentPrivateKey);
    const walletClient = createWalletClient({
      account,
      chain: mezoTestnet,
      transport: http(),
    });

    return await walletClient.writeContract({
      address: routerAddress,
      abi: ROUTER_ABI,
      functionName: "settleX402Invoice",
      args: [
        {
          invoiceId: challenge.invoiceId,
          merchant: challenge.payTo,
          amountMusd: BigInt(challenge.maxAmountRequired),
          expiryTimestamp: BigInt(challenge.expiryTimestamp),
          resourceUri: challenge.resource,
        },
      ],
    });
  }

  /**
   * Verifies on Mezo Testnet (31611) that the settlement transaction succeeded before releasing the API payload.
   */
  public async verifyReceiptOnMezo(txHash: Hex): Promise<boolean> {
    const receipt = await this.publicClient.waitForTransactionReceipt({ hash: txHash, confirmations: 1 });
    return receipt.status === "success";
  }
}