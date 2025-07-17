// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IPSM.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeMath.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";

contract PSMAdapter is IAdapter {

    address public immutable PSMUSDC_ADDRESS;
    address public immutable PSMGUSD_ADDRESS;
    address public immutable PSMUSDP_ADDRESS;
    address public immutable USDC_ADDRESS;
    address public immutable GUSD_ADDRESS;
    address public immutable USDP_ADDRESS;
    address public immutable DAI_ADDRESS;

    uint256 constant WAD = 10 ** 18;

    uint256 constant SZABO = 10 ** 12;     //to18ConversionFactor of USDC, demical of USDC is 6
    uint256 constant GUSDFACTOR = 10 ** 16;//to18ConversionFactor of GUSD, demical of GUSD is 2
    uint256 constant USDPFACTOR = 1;       //to18ConversionFactor of USDP, demical of USDP is 18
    address constant AUTHGEMJOIN_USDC_ADDRESS = 0x0A59649758aa4d66E25f08Dd01271e891fe52199;
    address constant AUTHGEMJOIN_GUSD_ADDRESS = 0x79A0FA989fb7ADf1F8e80C93ee605Ebb94F7c6A5;
    address constant AUTHGEMJOIN_USDP_ADDRESS = 0x7bbd8cA5e413bCa521C2c80D8d1908616894Cf21;

    constructor(address _dss_psm_usdc, address _dss_psm_gusd, address _dss_psm_usdp, address _usdc, address _gusd, address _usdp, address _dai) {
        PSMUSDC_ADDRESS = _dss_psm_usdc;
        PSMGUSD_ADDRESS = _dss_psm_gusd;
        PSMUSDP_ADDRESS = _dss_psm_usdp;
        USDC_ADDRESS = _usdc;
        GUSD_ADDRESS = _gusd;
        USDP_ADDRESS = _usdp;
        DAI_ADDRESS = _dai;
    }
    /*
    _dss_psm_usdc = 0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A;
    _dss_psm_gusd = 0x204659B2Fd2aD5723975c362Ce2230Fba11d3900;
    _dss_psm_usdp = 0x961Ae24a1Ceba861D1FDf723794f6024Dc5485Cf;
    _usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    _gusd = 0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd;
    _usdp = 0x8E870D67F660D95d5be530380D0eC0bd388289E1;
    _dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    */


    function _psmSwap(
        address to,
        address,
        bytes memory moreInfo
    ) internal {
        IPSM dssPsm_USDC = IPSM(PSMUSDC_ADDRESS);
        IPSM dssPsm_GUSD = IPSM(PSMGUSD_ADDRESS);
        IPSM dssPsm_USDP = IPSM(PSMUSDP_ADDRESS);
        (address sourceToken, address targetToken) = abi.decode(
            moreInfo,
            (address, address)
        );
        uint256 sellAmount = IERC20(sourceToken).balanceOf(address(this));
        if (sourceToken == USDC_ADDRESS) {
            require(targetToken == DAI_ADDRESS, "PSMAdapter: no support token");
            // approve origin psm
            SafeERC20.safeApprove(
                IERC20(sourceToken),
                AUTHGEMJOIN_USDC_ADDRESS,
                sellAmount
            );
            // usdc - dai
            dssPsm_USDC.sellGem(address(this),sellAmount);
            // approve 0
            SafeERC20.safeApprove(
                IERC20(sourceToken),
                AUTHGEMJOIN_USDC_ADDRESS,
                0
            );
        } else if (sourceToken == GUSD_ADDRESS) {
            require(targetToken == DAI_ADDRESS, "PSMAdapter: no support token");
            // approve origin psm
            SafeERC20.safeApprove(
                IERC20(sourceToken),
                AUTHGEMJOIN_GUSD_ADDRESS,
                sellAmount
            );
            // gusd - dai
            dssPsm_GUSD.sellGem(address(this),sellAmount);
            // approve 0
            SafeERC20.safeApprove(
                IERC20(sourceToken),
                AUTHGEMJOIN_GUSD_ADDRESS,
                0
            );
        } else if (sourceToken == USDP_ADDRESS) {
            require(targetToken == DAI_ADDRESS, "PSMAdapter: no support token");
            // approve origin psm
            SafeERC20.safeApprove(
                IERC20(sourceToken),
                AUTHGEMJOIN_USDP_ADDRESS,
                sellAmount
            );
            // usdp - dai
            dssPsm_USDP.sellGem(address(this),sellAmount);
            // approve 0
            SafeERC20.safeApprove(
                IERC20(sourceToken),
                AUTHGEMJOIN_USDP_ADDRESS,
                0
            );
        } else if (sourceToken == DAI_ADDRESS) {
            require(targetToken == USDC_ADDRESS || targetToken == GUSD_ADDRESS || targetToken == USDP_ADDRESS, "PSMAdapter: no support token");
            if (targetToken == USDC_ADDRESS) {
                //calculate target amount and convert to target demicals
                uint256 tout = dssPsm_USDC.tout();
                uint256 buyAmount = buyGemAmount(tout, WAD, sellAmount, SZABO);
                // approve dsspsm_usdc
                SafeERC20.safeApprove(
                    IERC20(sourceToken),
                    PSMUSDC_ADDRESS,
                    sellAmount
                );
                // dai - usdc decimal need to be 6
                dssPsm_USDC.buyGem(address(this),buyAmount);
                // approve 0
                SafeERC20.safeApprove(
                    IERC20(sourceToken),
                    PSMUSDC_ADDRESS,
                    0
                );
            }else if (targetToken == GUSD_ADDRESS) {
                //calculate target amount and convert to target demicals
                uint256 tout = dssPsm_GUSD.tout();
                uint256 buyAmount = buyGemAmount(tout, WAD, sellAmount, GUSDFACTOR);
                // approve dsspsm_gusd
                SafeERC20.safeApprove(
                    IERC20(sourceToken),
                    PSMGUSD_ADDRESS,
                    sellAmount
                );
                // dai - gusd decimal need to be 2
                dssPsm_GUSD.buyGem(address(this),buyAmount);
                // approve 0
                SafeERC20.safeApprove(
                    IERC20(sourceToken),
                    PSMGUSD_ADDRESS,
                    0
                );
            }else {
                //calculate target amount and convert to target demicals
                uint256 tout = dssPsm_USDP.tout();
                uint256 buyAmount = buyGemAmount(tout, WAD, sellAmount, USDPFACTOR);
                // approve dsspsm_usdp
                SafeERC20.safeApprove(
                    IERC20(sourceToken),
                    PSMUSDP_ADDRESS,
                    sellAmount
                );
                // dai - usdp decimal need to be 18
                dssPsm_USDP.buyGem(address(this),buyAmount);
                // approve 0
                SafeERC20.safeApprove(
                    IERC20(sourceToken),
                    PSMUSDP_ADDRESS,
                    0
                );
            }
        } else {
            revert("PSMAdapter: no support token");
        }

        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(targetToken),
                to,
                IERC20(targetToken).balanceOf(address(this))
            );
        }
    }

    // If tout is no longer 0，use this function ‘buyGemAmount(tout, wad, sellAmount)’  instead of sellAmount in buyGem
    function buyGemAmount(uint256 tout, uint256 wad, uint256 daiAmt, uint256 to18Factor) internal pure returns (uint256){
        uint256 a = SafeMath.mul(daiAmt,wad);
        uint256 b = SafeMath.add(wad,tout);
        uint256 buyGemAmt = SafeMath.div(a, b);
        uint256 buyGemRealAmt = SafeMath.div(buyGemAmt, to18Factor);
        return buyGemRealAmt;
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _psmSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _psmSwap(to, pool, moreInfo);
    }

}
