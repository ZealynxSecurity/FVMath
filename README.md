
# First Flight #8: Math Master - Findings Report

# Table of contents
- ## [Contest Summary](#contest-summary)
- ## [Results Summary](#results-summary)
- ## High Risk Findings
    - ### [H-01. Flawed Rounding Mechanism in mulWadUp Function](#H-01)




# <a id='contest-summary'></a>Contest Summary

### Sponsor: First Flight #8

### Dates: Jan 25th, 2024 - Feb 2nd, 2024

[See more contest details here](https://www.codehawks.com/contests/clrp8xvh70001dq1os4gaqbv5)

# <a id='results-summary'></a>Results Summary

### Number of findings:
   - High: 1
   - Medium: 0
   - Low: 0


# High Risk Findings

## <a id='H-01'></a>H-01. Flawed Rounding Mechanism in mulWadUp Function            

### Relevant GitHub Links
	
https://github.com/Cyfrin/2024-01-math-master/blob/84c149baf09c1558d7ba3493c7c4e68d83e7b3aa/src/MathMasters.sol#L56

## Summary
- A discrepancy was identified in the results of two functions, solmateMulWadUp and mulWadUp, both designed for decimal number multiplication and rounding up the result. 
- The test failed for certain large values, suggesting an issue in handling rounding or overflow.

## Vulnerability Details
- The mulWadUp function appears to have a problem in its rounding logic for large values. It uses inline assembly with a series of checks and adjustments to compute the multiplication and rounding. 
- The failed test indicates that the function does not handle rounding consistently compared to solmateMulWadUp.

I have compared the function of the contract under analysis with the same function used in the Solmate repository contract:


```solidity
    function solmateMulWadUp(uint256 x, uint256 y) public pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(WAD, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), WAD), 0), div(mul(x, y), WAD))
        }
    }


    function mulWadUp(uint256 x, uint256 y) public pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, or(div(not(0), y), x))) {
                mstore(0x40, 0xbac65e5b) // `MathMasters__MulWadFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(sub(div(add(z, x), y), 1)) { x := add(x, 1) }
            z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
        }
    }
}
```

#### POC

```solidity
    function check_test_MulWadUpEquivalence(uint128 _x, uint128 _y) public {
        uint x = uint(_x);
        uint y = uint(_y);

        uint solmate = cu.solmateMulWadUp(x, y);
        uint mathmaster = cu.mulWadUp(x, y);

        assert(solmate == mathmaster);
    }
```

#### Result
 
```js
Running 1 tests for test/MathMasters.t.sol:MathMastersTest
[FAIL] check_test__MulWadUpCorrectness(uint128,uint128) (paths: 3/8, time: 174.88s, bounds: [])
Counterexample:
    p__x_uint128 = 0x000000000000000000000000000000005a0491e7f0a78c29cd37215f92a63031 (119654248133653593030540106805042098225)
    p__y_uint128 = 0x0000000000000000000000000000000045800066363afac8a139b0061fe9ee93 (92381353805107722142254349841582386835)
```

## Impact
The primary impact is inconsistency in computation results, particularly for large values. This could lead to unexpected outcomes in the application and potentially affect operations reliant on this function.


## Tools Used

Halmos

## Recommendations

- It is recommended to review and adjust the rounding logic in mulWadUp. A potential solution is to modify the function to appropriately check for the division remainder and apply upward rounding accurately. 
- This would ensure that the function behaves as expected in all cases, especially for large numerical values.

```solidity
function mulWadUp(uint256 x, uint256 y) public pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
        // Check for overflow in the multiplication
        if mul(y, gt(x, div(MAX_UINT256, y))) {
            revert(0, 0)
        }

        let product = mul(x, y)
        z := div(product, WAD)

        // Check if there's a remainder, and if so, round up
        if gt(mod(product, WAD), 0) {
            z := add(z, 1)
        }
    }
}
```

- In this corrected version, the multiplication is performed first and then checked if there is a remainder in the division by WAD. If there is a remainder, 1 is added to the result to ensure rounding up. 
- This logic should correctly handle test cases like the one you provided, ensuring that the function behaves as expected in all cases.

		





