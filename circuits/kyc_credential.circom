pragma circom 2.1.9;

include "circomlib/circuits/eddsa.circom";
include "circomlib/circuits/poseidon.com";
include "circomlib/circuits/comparators.com";

/*
 * @title KYCCredential Circuit
 * @author Digital Asset
 * @notice This circuit generates a zero-knowledge proof for a Know Your Customer (KYC) credential.
 *
 * It allows a prover (the subject of the KYC) to demonstrate to a verifier that they hold a
 * valid, non-expired KYC credential issued by a trusted authority, without revealing any
 * personally identifiable information (PII) or even the identity of the issuer.
 *
 * The proof verifies three key properties:
 * 1. Authenticity: The credential was digitally signed by a valid issuer.
 * 2. Authority: The issuer is on a list of authorities trusted by the verifier.
 * 3. Timeliness: The credential is currently valid (i.e., not expired and issued in the past).
 */
template KYCCredential(n, k) {

    // === Private Inputs ===
    // These signals are known only to the prover.

    // Issuer's EdDSA public key (e.g., the KYC provider's public key)
    signal input issuerAx;
    signal input issuerAy;

    // EdDSA signature from the issuer over the `credentialHash`
    signal input R8x;
    signal input R8y;
    signal input S;

    // The message that was signed by the issuer. This is typically a Poseidon hash
    // of the user's PII, credential ID, and dates to ensure data integrity.
    // It's split into `k` chunks to fit within the finite field.
    signal input credentialHash[k];

    // Validity period of the credential, represented as Unix timestamps or similar numeric format.
    signal input issuanceDate;
    signal input expirationDate;

    // === Public Inputs ===
    // These signals are known to both the prover and the verifier.

    // A Poseidon hash of a trusted issuer's public key. The verifier provides this
    // to constrain the proof to a specific trusted authority without revealing the
    // authority's full public key on-chain or in public records.
    signal input allowedIssuerPublicKeyHash;

    // The current date/time, provided by the verifier as a public input.
    // This prevents replay attacks with proofs for credentials that have since expired.
    signal input currentDate;

    // === Circuit Logic ===

    // --- 1. Verify Issuer Signature ---
    // This component checks that the provided signature (R8x, R8y, S) is valid for the
    // `credentialHash` under the `issuer`'s public key.
    // If the signature is invalid, proof generation will fail. This enforces authenticity.
    component eddsaVerifier = EdDSAPoseidonVerifier(n, k);

    eddsaVerifier.enabled <== 1;
    eddsaVerifier.Ax <== issuerAx;
    eddsaVerifier.Ay <== issuerAy;
    eddsaVerifier.R8x <== R8x;
    eddsaVerifier.R8y <== R8y;
    eddsaVerifier.S <== S;
    for (var i = 0; i < k; i++) {
        eddsaVerifier.M[i] <== credentialHash[i];
    }

    // --- 2. Verify Issuer Authority ---
    // This section confirms that the issuer of the credential is one trusted by the verifier.
    // We compute the Poseidon hash of the issuer's public key (provided as a private input)
    // and constrain it to equal the `allowedIssuerPublicKeyHash` (a public input).
    component issuerKeyHasher = Poseidon(2);
    issuerKeyHasher.inputs[0] <== issuerAx;
    issuerKeyHasher.inputs[1] <== issuerAy;

    component isTrustedIssuer = IsEqual();
    isTrustedIssuer.in[0] <== issuerKeyHasher.out;
    isTrustedIssuer.in[1] <== allowedIssuerPublicKeyHash;
    isTrustedIssuer.out === 1; // Constraint: must be a trusted issuer.

    // --- 3. Verify Credential Timeliness ---
    // These checks ensure the credential is currently active.
    // We assume dates are represented as numbers that fit within 64 bits (e.g., Unix seconds).

    // Check 3a: `currentDate` must be greater than or equal to `issuanceDate`.
    // The `GreaterThan` component checks for strict inequality (a > b). To check a >= b, we check b < a+1.
    component isAfterIssuance = LessThan(64);
    isAfterIssuance.in[0] <== issuanceDate;
    isAfterIssuance.in[1] <== currentDate + 1;
    isAfterIssuance.out === 1; // Constraint: must be currently active.

    // Check 3b: `currentDate` must be less than `expirationDate`.
    component isBeforeExpiration = LessThan(64);
    isBeforeExpiration.in[0] <== currentDate;
    isBeforeExpiration.in[1] <== expirationDate;
    isBeforeExpiration.out === 1; // Constraint: must not be expired.
}

// Instantiate the circuit with concrete parameters.
// n=251 is for the BabyJubJub curve, commonly used with EdDSA in ZK circuits.
// k=1 assumes the credential hash (the message) fits into a single field element,
// which is true if it's the output of a Poseidon hash.
component main { public [allowedIssuerPublicKeyHash, currentDate] } = KYCCredential(251, 1);