// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./Braindao.sol";

contract BraindaoTest is DSTest {
    Braindao braindao;

    function setUp() public {
        braindao = new Braindao();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
