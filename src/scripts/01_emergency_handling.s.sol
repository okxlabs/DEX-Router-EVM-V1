// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import "@dex/TokenApprove.sol";

contract EmergencyHandling is Script {
    address owner = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    address constant TOKENAPPROVE_OWNER =
        0x06C95a3934d94d5ae5bf54731bD2840ceFee6F87;

    mapping(string => address) private _tokenApproves;
    mapping(string => address) private _approveProxys;

    function setUp() public {
        // tokenApprove
        _tokenApproves["arb"] = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
        _tokenApproves["avax"] = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
        _tokenApproves["base"] = 0x57df6092665eb6058DE53939612413ff4B09114E;
        _tokenApproves["bsc"] = 0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6;
        _tokenApproves["conflux"] = 0x68D6B739D2020067D1e2F713b999dA97E4d54812;
        _tokenApproves["cro"] = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
        _tokenApproves["eth"] = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
        _tokenApproves["ethw"] = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
        _tokenApproves["flare"] = 0x808ca026D4c45d6A41c1e807c41044480b7699eF;
        _tokenApproves["ftm"] = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
        _tokenApproves["linea"] = 0x57df6092665eb6058DE53939612413ff4B09114E;
        _tokenApproves["mantle"] = 0x57df6092665eb6058DE53939612413ff4B09114E;
        _tokenApproves["okc"] = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
        _tokenApproves["op"] = 0x68D6B739D2020067D1e2F713b999dA97E4d54812;
        _tokenApproves["polygon"] = 0x3B86917369B83a6892f553609F3c2F439C184e31;
        _tokenApproves[
            "polyzkevm"
        ] = 0x57df6092665eb6058DE53939612413ff4B09114E;
        _tokenApproves["scroll"] = 0x57df6092665eb6058DE53939612413ff4B09114E;

        // approveProxy
        _approveProxys["arb"] = 0xE9BBD6eC0c9Ca71d3DcCD1282EE9de4F811E50aF;
        _approveProxys["avax"] = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
        _approveProxys["base"] = 0x1b5d39419C268b76Db06DE49e38B010fbFB5e226;
        _approveProxys["bsc"] = 0xd99cAE3FAC551f6b6Ba7B9f19bDD316951eeEE98;
        _approveProxys["conflux"] = 0x100F3f74125C8c724C7C0eE81E4dd5626830dD9a;
        _approveProxys["cro"] = 0xE9BBD6eC0c9Ca71d3DcCD1282EE9de4F811E50aF;
        _approveProxys["eth"] = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
        _approveProxys["ethw"] = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
        _approveProxys["flare"] = 0xE9BBD6eC0c9Ca71d3DcCD1282EE9de4F811E50aF;
        _approveProxys["ftm"] = 0xE9BBD6eC0c9Ca71d3DcCD1282EE9de4F811E50aF;
        _approveProxys["linea"] = 0x1b5d39419C268b76Db06DE49e38B010fbFB5e226;
        _approveProxys["mantle"] = 0x1b5d39419C268b76Db06DE49e38B010fbFB5e226;
        _approveProxys["okc"] = 0xE9BBD6eC0c9Ca71d3DcCD1282EE9de4F811E50aF;
        _approveProxys["op"] = 0x100F3f74125C8c724C7C0eE81E4dd5626830dD9a;
        _approveProxys["polygon"] = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
        _approveProxys[
            "polyzkevm"
        ] = 0x1b5d39419C268b76Db06DE49e38B010fbFB5e226;
        _approveProxys["scroll"] = 0x1b5d39419C268b76Db06DE49e38B010fbFB5e226;
    }

    // forge script src/scripts/01_emergency_handling.s.sol --sig "pauseTokenApprove(string[])" '[arb,avax,base,bsc,conflux,cro,eth,ethw,flare,ftm,linea,mantle,okc,op,polygon,polyzkevm,scroll]' -vvv --broadcast
    function pauseTokenApprove(string[] memory chains) public {
        require(
            owner == TOKENAPPROVE_OWNER,
            "wrong owner! change the private key"
        );

        for (uint256 i = 0; i < chains.length; ++i) {
            address tokenApprove = _tokenApproves[chains[i]];
            require(tokenApprove != address(0), "zero address");

            vm.createSelectFork(chains[i]);

            address originApproveProxy = TokenApprove(_tokenApproves[chains[i]])
                .tokenApproveProxy();
            assert(originApproveProxy == _approveProxys[chains[i]]);

            console2.log(
                "## Pause Chain: [%s] TokenApprove:[%s] originApproveProxy:[%s] start",
                chains[i],
                tokenApprove,
                originApproveProxy
            );

            vm.startBroadcast(owner);

            //vm.prank(TOKENAPPROVE_OWNER);
            TokenApprove(_tokenApproves[chains[i]]).setApproveProxy(address(0));

            vm.stopBroadcast();

            console2.log(
                "## Pause Chain: [%s] TokenApprove:[%s] originApproveProxy:[%s] finished\n",
                chains[i],
                tokenApprove,
                originApproveProxy
            );
        }
    }

    // forge script src/scripts/01_emergency_handling.s.sol --sig "recoverTokenApprove(string[])" '[arb,avax,base,bsc,conflux,cro,eth,ethw,flare,ftm,linea,mantle,okc,op,polygon,polyzkevm,scroll]' -vvv --broadcast
    function recoverTokenApprove(string[] memory chains) public {
        require(
            owner == TOKENAPPROVE_OWNER,
            "wrong owner! change the private key"
        );

        for (uint256 i = 0; i < chains.length; ++i) {
            address tokenApprove = _tokenApproves[chains[i]];
            require(tokenApprove != address(0), "zero address");

            vm.createSelectFork(chains[i]);

            address originApproveProxy = TokenApprove(_tokenApproves[chains[i]])
                .tokenApproveProxy();

            console2.log(
                "## Recover Chain: [%s] TokenApprove:[%s] originApproveProxy:[%s] start",
                chains[i],
                tokenApprove,
                originApproveProxy
            );

            vm.startBroadcast(owner);

            //vm.prank(TOKENAPPROVE_OWNER);
            TokenApprove(_tokenApproves[chains[i]]).setApproveProxy(
                _approveProxys[chains[i]]
            );

            vm.stopBroadcast();

            console2.log(
                "## Recover Chain: [%s] TokenApprove:[%s] approveProxy:[%s] finished\n",
                chains[i],
                tokenApprove,
                _approveProxys[chains[i]]
            );
        }
    }
}
