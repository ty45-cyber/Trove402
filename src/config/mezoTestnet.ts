import { defineChain } from "viem";

export const mezoTestnet = defineChain({
  id: 31611,
  name: "Mezo Testnet",
  nativeCurrency: {
    decimals: 18,
    name: "Bitcoin",
    symbol: "BTC",
  },
  rpcUrls: {
    default: {
      http: ["https://rpc.test.mezo.org"],
      webSocket: ["wss://rpc-ws.test.mezo.org"],
    },
  },
  blockExplorers: {
    default: {
      name: "Mezo Testnet Explorer",
      url: "https://explorer.test.mezo.org",
    },
  },
  testnet: true,
});

export const MEZO_TESTNET_CONTRACTS = {
  CAIP2_NETWORK: "eip155:31611",
  MEZO_CREDIT_VAULT: "0xEf7d9d1BF0532eBa6C1eEefDA4949a31C6F43E22",
  X402_SETTLEMENT_ROUTER: "0xa750ea11cb38f1E2B7cd985F9EEB07A3cB8F6C63",
  MUSD_TOKEN: "0x118917a40FAF1CD7a13dB0Ef56C86De7973Ac503",
  BORROWER_OPERATIONS: "0xCdF7028ceAB81fA0C6971208e83fa7872994beE5",
  PRICE_FEED: "0x86bCF0841622a5dAC14A313a15f96A95421b9366",
  STABILITY_POOL: "0x1CCA7E410eE41739792eA0A24e00349Dd247680e",
  HINT_HELPERS: "0x4e4cBA3779d56386ED43631b4dCD6d8EacEcBCF6",
  SORTED_TROVES: "0x722E4D24FD6Ff8b0AC679450F3D91294607268fA",
  TROVE_MANAGER: "0x7FE0A5a7EeBD88530c58824475edEae33424671F",
} as const;

export const ROUTER_ABI = [
  {
    type: "function",
    name: "configureAgentPolicy",
    stateMutability: "nonpayable",
    inputs: [
      { name: "agent", type: "address" },
      { name: "dailyLimitMusd", type: "uint128" },
      { name: "active", type: "bool" },
    ],
    outputs: [],
  },
  {
    type: "function",
    name: "settleX402Invoice",
    stateMutability: "nonpayable",
    inputs: [
      {
        name: "invoice",
        type: "tuple",
        components: [
          { name: "invoiceId", type: "bytes32" },
          { name: "merchant", type: "address" },
          { name: "amountMusd", type: "uint256" },
          { name: "expiryTimestamp", type: "uint64" },
          { name: "resourceUri", type: "string" },
        ],
      },
    ],
    outputs: [],
  },
] as const;
