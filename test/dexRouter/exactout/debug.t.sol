// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/BaseTestSetup.t.sol";

contract debug is BaseTestSetup {

    function testParseCommissionInfo() public {
        bytes memory commissionInfo = hex"22220afc2aaa0000007a1200db5df573774f2acb0df3bf72ab1cf6053325174e800000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22220afc2aaa0000001e8480dcf79745ce776d54e50253033d5f3c281212d989";

        CommissionInfo memory info = _parseCommissionInfo(commissionInfo);
        console2.log("isFromTokenCommission:", info.isFromTokenCommission);
        console2.log("isToTokenCommission:", info.isToTokenCommission);
        console2.log("token:", info.token);
        console2.log("commissionRate:", info.commissionRate);
        console2.log("refererAddress:", info.refererAddress);
        console2.log("commissionRate2:", info.commissionRate2);
        console2.log("refererAddress2:", info.refererAddress2);
        console2.log("isToBCommission:", info.isToBCommission);
        console2.log("isDualCommission:", info.isDualCommission);
    }

    function testBuildAndParseCommissionInfo() public {
        // Build commission info with expected parameters
        bytes memory builtCommission = _buildCommissionInfoUnified(
            true,   // isFromTokenCommission
            false,  // isToTokenCommission
            COMMISSION_ETH,  // token
            200,    // commissionRate
            address(0xba200B05fc575A58C409401Be3a3734a7F99B0CD),  // refererAddress
            100,    // commissionRate2
            address(0x77FeD66f0E339209C7B641dB06B33059A7a2c1e2),  // refererAddress2
            true    // isToBCommission
        );
        
        console2.log("Built commission info:");
        console2.logBytes(builtCommission);
        
        CommissionInfo memory info = _parseCommissionInfo(builtCommission);
        console2.log("Parsed commission info:");
        console2.log("isFromTokenCommission:", info.isFromTokenCommission);
        console2.log("isToTokenCommission:", info.isToTokenCommission);
        console2.log("token:", info.token);
        console2.log("commissionRate:", info.commissionRate);
        console2.log("refererAddress:", info.refererAddress);
        console2.log("commissionRate2:", info.commissionRate2);
        console2.log("refererAddress2:", info.refererAddress2);
        console2.log("isToBCommission:", info.isToBCommission);
        console2.log("isDualCommission:", info.isDualCommission);
    }

} 