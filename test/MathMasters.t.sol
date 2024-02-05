// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.3;

// import {Base_Test, console2} from "./Base_Test.t.sol";
import {MathMasters} from "src/MathMasters.sol";

import "../src/functions/MulWad.sol";
import "../src/functions/MulWadUp.sol";
import "../src/functions/Sqr.sol";

import {Test, console} from "forge-std/Test.sol";

import {SymTest} from "halmos-cheatcodes/SymTest.sol";


contract MathMastersTest is Test  {

    MulWad c;
    MulWadUp cu;
    Sqr sqr;


    function setUp() public {
        c = new MulWad();
        cu = new MulWadUp();
        sqr = new Sqr();

    }

    // function testMulWad() public {
    //     assertEq(MathMasters.mulWad(2.5e18, 0.5e18), 1.25e18);
    //     assertEq(MathMasters.mulWad(3e18, 1e18), 3e18);
    //     assertEq(MathMasters.mulWad(369, 271), 0);
    // }

    // function testMulWadFuzz(uint256 x, uint256 y) public pure {
    //     // Ignore cases where x * y overflows.
    //     unchecked {
    //         if (x != 0 && (x * y) / x != y) return;
    //     }
    //     assert(MathMasters.mulWad(x, y) == (x * y) / 1e18);
    // }

    // function testMulWadUp() public {
    //     assertEq(MathMasters.mulWadUp(2.5e18, 0.5e18), 1.25e18);
    //     assertEq(MathMasters.mulWadUp(3e18, 1e18), 3e18);
    //     assertEq(MathMasters.mulWadUp(369, 271), 1);
    // }

    // function testMulWadUpFuzz(uint256 x, uint256 y) public {
    //     // We want to skip the case where x * y would overflow.
    //     // Since Solidity 0.8.0 checks for overflows by default,
    //     // we cannot just multiply x and y as this could revert.
    //     // Instead, we can ensure x or y is 0, or
    //     // that y is less than or equal to the maximum uint256 value divided by x
    //     if (x == 0 || y == 0 || y <= type(uint256).max / x) {
    //         uint256 result = MathMasters.mulWadUp(x, y);
    //         uint256 expected = x * y == 0 ? 0 : (x * y - 1) / 1e18 + 1;
    //         assertEq(result, expected);
    //     }
    //     // If the conditions for x and y are such that x * y would overflow,
    //     // this function will simply not perform the assertion.
    //     // In a testing context, you might want to handle this case differently,
    //     // depending on whether you want to consider such an overflow case as passing or failing.
    // }

    // function testSqrt() public {
    //     assertEq(MathMasters.sqrt(0), 0);
    //     assertEq(MathMasters.sqrt(1), 1);
    //     assertEq(MathMasters.sqrt(2704), 52);
    //     assertEq(MathMasters.sqrt(110889), 333);
    //     assertEq(MathMasters.sqrt(32239684), 5678);
    //     assertEq(MathMasters.sqrt(type(uint256).max), 340282366920938463463374607431768211455);
    // }

    // function testSqrtFuzzUni(uint256 x) public pure {
    //     assert(MathMasters.sqrt(x) == uniSqrt(x));
    // }

    // function testSqrtFuzzSolmate(uint256 x) public pure {
    //     assert(MathMasters.sqrt(x) == solmateSqrt(x));
    // }


/////////////////////////////////

// SOLUTIONS

////////////////////////////////


/////////////////////////////////
// mulWad
////////////////////////////////
    function Check__MulWadCorrectnessAndEquivalence(uint128 _x, uint128 _y) public {
        // uint x = svm.createUint256("x");
        // uint y = svm.createUint256("y");
        uint x = uint(_x);
        uint y = uint(_y);

        uint solution = x * y / c.WAD();
        uint solmate = c.solmateMulWadDown(x, y);
        uint solady = c.soladyMulWad(x, y);
        // uint mathmaster = MathMasters.mulWad(x, y);
        uint mathmaster = c.mulWad(x, y);


        assertEq(solution, solmate);
        assertEq(solution, solady);
        assertEq(solution, mathmaster);

        assertEq(solady, mathmaster);
        assertEq(solmate, mathmaster);
        assertEq(solmate, solady);
    }

/////////////////////////////////
// mulWadUp
////////////////////////////////

// FUZZ
    function test__MulWadUpCorrectness(uint128 _x, uint128 _y) public {

        uint x = uint(_x);
        uint y = uint(_y);

        uint solution = x * y / c.WAD();
        if (solution * c.WAD() < x * y) {
            solution += 1;
        }

        uint solmate = cu.solmateMulWadUp(x, y);
        uint solady = cu.soladyMulWadUp(x, y);
        uint mathmaster = cu.mulWadUp(x, y);

        // assertEq(solution, solmate);
        // assertEq(solution, solady);
        assertEq(solution, mathmaster);
        console.log("result",solution);
        console.log("result",mathmaster);
        console.log("x",x);
        console.log("y",y);


    }

// FV
    function test_MulWadUpEquivalence(uint128 _x, uint128 _y) public {
        uint x = uint(_x);
        uint y = uint(_y);

        uint solmate = cu.solmateMulWadUp(x, y);
        // uint solady = cu.soladyMulWadUp(x, y);
        uint mathmaster = cu.mulWadUp(x, y);


        // assertEq(solmate, solady);
        assert(solmate == mathmaster);
        // assertEq(solady, mathmaster);
    }


// UNIT FV
    function test_FV_Result() public {

        uint128 x = 119654248133653593030540106805042098225;
        uint128 y = 92381353805107722142254349841582386835;

        uint solmate = cu.solmateMulWadUp(x, y);
        uint mathmaster = cu.mulWadUp(x, y);

        assert(solmate == mathmaster);

    }

// UNIT FUZZ
    function test_Fuzz_Result() public {

        uint128 x = 340282366920938463463374607431768211453;
        uint128 y = 170141183460469231731687303715884105727;

        uint solmate = cu.solmateMulWadUp(x, y);
        uint mathmaster = cu.mulWadUp(x, y);

        assert(solmate == mathmaster);

    }

/////////////////////////////////
// Sqrt
////////////////////////////////

    function test__SqrtCorrectness(uint32 solution, uint32 rand) public {
        vm.assume(solution > 0);

        uint squaredPlus = uint64(solution) * solution + (rand % solution);
        uint solmate = sqr.solmateSqrt(squaredPlus);
        uint solady = sqr.soladySqrt(squaredPlus);
        uint mathmaster = sqr.sqrt(squaredPlus);

        // assertEq(solution, solmate);
        // assertEq(solution, solady);
        assertEq(solution, mathmaster);
    }

    // Symbolic test to confirm that the differences between two functions result in same output.
    /// @custom:halmos --solver-timeout-assertion 0
    function test_check_SqrtEquivalence(uint x) public {

        uint solmate = sqr.solmateSqrt(x);
        // uint solady = sqr.soladySqrt(x);
        uint mathmaster = sqr.sqrt(x);

        assert(solmate == mathmaster);
    }
}
