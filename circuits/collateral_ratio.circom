pragma circom 2.1.8;

include "circomlib/circuits/comparators.circom";

/*
 * @title CollateralRatio
 * @author Digital Asset
 * @notice Proves that a position is overcollateralized without revealing the
 *         underlying collateral or debt values.
 *
 * This circuit verifies the inequality:
 *   collateralValue * precision >= debtValue * requiredRatio
 *
 * This is rearranged to `debtValue * requiredRatio <= collateralValue * precision`
 * for the comparison logic.
 *
 * The `precision` factor is used to handle decimal values, as Circom works
 * with field elements (large integers). For example, to represent a ratio of 1.5,
 * one might use a `requiredRatio` of 150 and a `precision` of 100.
 *
 * @param n The bit-width for the comparison, ensuring that the intermediate
 *          products do not overflow. A value like 250 is safe for most financial
 *          use cases, given the ~254-bit field size of the BN254 curve.
 */
template CollateralRatio(n) {
    // === Private Inputs ===
    // These are the secret values known only to the prover.

    // The total value of the collateral assets, scaled to an integer.
    signal private input collateralValue;
    // The total value of the debt obligations, scaled to an integer.
    signal private input debtValue;

    // === Public Inputs ===
    // These are known to both the prover and the verifier.

    // The required collateralization ratio, scaled to an integer.
    // e.g., For a 150% ratio, this could be 150.
    signal public input requiredRatio;
    // The precision factor used to scale decimal numbers to integers.
    // e.g., If requiredRatio is 150 to represent 1.5, precision should be 100.
    signal public input precision;


    // === Circuit Logic ===

    // Calculate the two sides of the inequality.
    // Left-hand side: debtValue * requiredRatio
    signal lhs;
    lhs <== debtValue * requiredRatio;

    // Right-hand side: collateralValue * precision
    signal rhs;
    rhs <== collateralValue * precision;

    // We want to prove that lhs <= rhs.
    // Circom's standard library provides a `LessThan` component, which checks for strict inequality (<).
    // The check `lhs <= rhs` is equivalent to checking that `rhs < lhs` is false.
    // The `LessThan(n)` component outputs 1 if `in[0] < in[1]` and 0 otherwise.

    component lt = LessThan(n);
    lt.in[0] <== rhs;
    lt.in[1] <== lhs;

    // We constrain the output of the LessThan component to be 0.
    // This enforces that `rhs` is NOT less than `lhs`, which means `rhs >= lhs`.
    // This is the overcollateralization condition we want to prove.
    lt.out === 0;
}


/*
 * @dev Instantiation of the CollateralRatio template with a 250-bit width.
 *      This provides a concrete component that can be used in other circuits or compiled directly.
 */
component main {public [requiredRatio, precision]} = CollateralRatio(250);