# Canton ZK-Attestation Protocol

[![Build Status](https://github.com/digital-asset/canton-zk-attestation/actions/workflows/ci.yml/badge.svg)](https://github.com/digital-asset/canton-zk-attestation/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

A zero-knowledge proof layer for Canton, enabling participants to prove verifiable statements about private data without revealing the underlying data itself. This protocol preserves Canton's "privacy by design" model while enabling trust and compliance in multi-party workflows.

This is a critical privacy-enhancing technology (PET) for institutional DeFi, allowing parties to meet regulatory requirements or counterparty risk checks without exposing sensitive information like portfolio composition, net worth, or trading strategies.

## The Problem: Proving Facts Without Revealing Secrets

Canton's privacy model is powerful: only stakeholders to a transaction see its data. However, this creates a challenge when you need to prove something about your private data to a party who is *not* a stakeholder.

Consider these scenarios:
*   A borrower wants to prove to a lender that their collateral portfolio is worth at least 150% of their loan value, without revealing the specific assets they hold.
*   A hedge fund needs to prove to an auditor that it is complying with asset allocation mandates, without giving the auditor full read access to its live positions.
*   A user wants to access a permissioned liquidity pool by proving they have a valid KYC credential, without revealing their personal identity to all other pool participants.

In each case, the prover needs to convince a verifier of a fact, while keeping the underlying data (the "witness") private.

## The Solution: On-Ledger Attestations Backed by ZK Proofs

This project implements a Daml-based protocol for requesting, generating, and verifying zero-knowledge attestations on Canton.

The core idea is to combine the strengths of Daml's permissioned contract model with the cryptographic security of off-ledger ZK proof generation.

*   **Provable Statements:** The protocol allows a verifier to request a proof of a specific, pre-defined statement (e.g., "collateral ratio > 1.5").
*   **Off-Ledger Proof Generation:** The prover uses an off-ledger client to gather their private Canton contract data, generate a ZK proof, and submit it to the ledger.
*   **On-Ledger Verification:** The proof is verified by the Daml contract logic. If valid, a `VerifiableAttestation` contract is created.
*   **Durable, Verifiable Credential:** The `VerifiableAttestation` acts as a signed, tamper-proof, on-ledger credential that can be shared with other parties (like regulators or auditors) as definitive proof of the statement.

---

## How It Works: The Attestation Flow

![ZK Attestation Flow Diagram](docs/flow.png)
*(Note: Diagram to be added in `docs/flow.png`)*

1.  **Request:** The **Verifier** (e.g., Lender) creates an `AttestationRequest` contract on the ledger, inviting the **Prover** (e.g., Borrower) to prove a specific statement. The request defines the `circuitId` (the logic to be proven) and any public inputs.
2.  **Gather Witness:** The Prover's off-ledger agent is notified of the request. It queries the Prover's private active contracts on the Canton ledger to gather the necessary data (the "witness"). For example, it would fetch all of the Prover's `Asset` contracts to calculate their total portfolio value.
3.  **Generate Proof:** The off-ledger agent feeds the private witness data and public inputs into a corresponding ZK circuit (e.g., written in Circom or Noir) to generate a cryptographic proof and the public outputs.
4.  **Submit Proof:** The Prover exercises the `ProvideProof` choice on the `AttestationRequest` contract, submitting the generated proof and public outputs.
5.  **Verify & Attest:** The Daml contract logic validates the proof. In this implementation, this is simulated, but in a production environment, it would call out to a trusted off-ledger verifier service or eventually use a native on-ledger verification function.
6.  **Confirmation:** If the proof is valid, the `AttestationRequest` is consumed and a new `VerifiableAttestation` contract is created. This contract is signed by both the Prover and Verifier and serves as immutable, on-ledger evidence that the statement was true at a specific point in time.

## Key Use Cases

### 1. Overcollateralized Lending & Margin Calls
A borrower can prove their collateral value exceeds a required threshold without revealing their entire portfolio to the lender. This can be used for loan origination or to respond to margin calls automatically and privately.

### 2. Private KYC/AML for DeFi
A user can obtain a `KycAttestation` from a trusted identity provider. They can then show this attestation to a DeFi protocol to gain access, proving they are verified without revealing their real-world identity to the protocol or other users.

### 3. Regulatory Reporting & Audits
A fund can provide an auditor with a `VerifiableAttestation` proving that its portfolio adheres to diversification rules (e.g., "no more than 5% of assets in a single security") without granting the auditor direct access to its sensitive trading accounts.

### 4. Risk Management & Credit Scoring
A trading firm can prove to a clearing house that its Value-at-Risk (VaR) is below a certain ceiling, or prove it has a certain amount of liquid capital, to qualify for lower margin requirements.

## Daml Model

*   `daml/Attestation/Request.daml`: The initial contract created by a Verifier to request a proof from a Prover.
*   `daml/Attestation/Verified.daml`: The final, immutable `VerifiableAttestation` contract that serves as the on-ledger credential.
*   `daml/Attestation/Circuits.daml`: Defines the types of statements that can be proven (e.g., `CollateralizationRatio`, `KycStatus`). It acts as a registry of supported ZK circuits.
*   `daml/Attestation/Interfaces.daml`: Defines common interfaces, such as `IAttestable`, that data contracts can implement to signal they can be used as witness data for proofs.

## Project Structure

```
.
├── daml/                     # Core Daml smart contracts
│   └── Attestation/
├── zk-circuits/              # (Future) Off-ledger circuit definitions (e.g., Circom)
├── prover-client/            # (Future) Sample off-ledger TypeScript client
├── daml.yaml                 # Daml project configuration
└── README.md
```

## Development

### Prerequisites
*   DPM (Daml Package Manager) `3.4.0` or higher.
*   A running Canton ledger.

### Build the Project
Compile the Daml code into a DAR (Daml Archive):
```bash
dpm build
```

### Run Tests
Execute the Daml Script tests defined in the project:
```bash
dpm test
```

### Start a Local Ledger
Run a local Canton sandbox environment with the JSON API enabled on port 7575:
```bash
dpm sandbox
```

## Future Work
- [ ] Integrate with a real ZK proving system like Circom/SnarkJS or Noir.
- [ ] Build a sample `prover-client` in TypeScript to demonstrate the end-to-end off-ledger flow.
- [ ] Develop a library of standard, audited circuits for common financial use cases.
- [ ] Explore integration with Canton's future native ZKP verification capabilities.