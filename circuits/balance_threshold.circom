pragma circom 2.1.5;

include "circomlib/circuits/comparators.circom";

/*
 * @title BalanceThreshold
 * @author Digital Asset
 * @notice Proves that a private `balance` is greater than or equal to a public `threshold`.
 * @dev This circuit is designed to be used in the Canton ZK Attestation framework.
 *      It leverages the `LessEqThan` comparator from circomlib to enforce the constraint:
 *      balance >= threshold  <=>  threshold <= balance
 *
 *      Inputs are assumed to be scaled integers representing fixed-precision decimals.
 *      For example, a balance of 123.45 with 10 decimal places would be passed as 1234500000000.
 *
 * @param n The number of bits to represent the balance and threshold.
 *          Must be chosen carefully to prevent overflow and fit within the field size.
 *          252 is a safe value for the bn254 curve.
 */
template BalanceThreshold(n) {
    // --- Inputs ---

    // The prover's private balance. This value is not revealed to the verifier.
    signal input balance;

    // The public threshold that the balance must meet or exceed.
    // This value is known to both the prover and the verifier.
    signal input threshold;

    // --- Constraints ---

    // To prove `balance >= threshold`, we use the `LessEqThan` component
    // from circomlib which checks if `in[0] <= in[1]`.
    // We wire `threshold` to `in[0]` and `balance` to `in[1]`.
    component comparator = LessEqThan(n);
    comparator.in[0] <== threshold;
    comparator.in[1] <== balance;

    // The `LessEqThan` component outputs 1 if the condition (threshold <= balance) is true,
    // and 0 otherwise. We constrain this output to be 1, which effectively
    // asserts that the condition holds. If it doesn't, the proof generation will fail.
    comparator.out === 1;
}

/*
 * @dev Main component instantiation for a 252-bit balance check.
 *      This size is chosen to be compatible with the scalar field of the bn254 curve,
 *      which is commonly used in ZK-SNARK systems like Groth16.
 *      The `threshold` is marked as a public input, making it part of the
 *      public statement being proven.
 */
component main { public [threshold] } = BalanceThreshold(252);