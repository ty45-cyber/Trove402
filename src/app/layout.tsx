import React from "react";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Trove402 | Mezo x402 Agentic MUSD Credit-Line Router",
  description: "Autonomous HTTP 402 MUSD settlement router backed by Mezo Trove & StabilityPool on Mezo Testnet (eip155:31611).",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body style={{ margin: 0, backgroundColor: "#fafafa", color: "#111" }}>
        {children}
      </body>
    </html>
  );
}
