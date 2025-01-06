const fs = require("fs");
const deployed = require('../deployed');

const UNXSWAP_ROUTER_PATH = "./contracts/8/libraries/CommonUtils.sol";
const PMMROUTER_PATH = "./contracts/8/PMMRouter.sol";
const EIP712_PATH = "./contracts/8/libraries/draft-EIP712Upgradable.sol";
const UNIV3_PATH = "./contracts/8/UnxswapV3Router.sol";

// Replaces the contract address in the constant part of the UnxswapRouter file
// _WETH, _APPROVE_PROXY_32, _WNATIVE_RELAY_32 Three constant addresses
// npx hardhat run scripts/tools/ureplace.js [network name, eg: eth]
function replace_contant(UnxswapRouterPath) {
  console.log(deployed.base);

  // Reading the file
  fs.readFile(UnxswapRouterPath, function (err, data) {
    if (err) {
      return console.error(err);
    }

    let context = data.toString();
    // address public constant
    context = context.replace(/_WETH\s+=\s+0x[0-9a-fA-F]+/, "_WETH = " + deployed.base.wNativeToken)
    context = context.replace(/_APPROVE_PROXY\s+=\s+0x[0-9a-fA-F]+/, "_APPROVE_PROXY = " + deployed.base.tokenApproveProxy)
    context = context.replace(/_WNATIVE_RELAY\s+=\s+0x[0-9a-fA-F]+/, "_WNATIVE_RELAY = " + deployed.base.wNativeRelayer)

    fs.writeFile(UnxswapRouterPath, context, (err) => {
      if (err) {
        console.log(err);
      }
    });

    console.log("replace finish !")
  });
}

function replace_pmm_contant(PMMROUTER_PATH) {
  console.log(deployed.base);

  // Reading the file
  fs.readFile(PMMROUTER_PATH, function (err, data) {
    if (err) {
      return console.error(err);
    }

    let context = data.toString();
    // address public constant
    context = context.replace(/_FACTORY\s=\s\w*/, "_FACTORY = " + deployed.base._FACTORY)

    fs.writeFile(PMMROUTER_PATH, context, (err) => {
      if (err) {
        console.log(err);
      }
    });

    console.log("replace finish !")
  });
}

function replace_pmm_eip712_contant(EIP712_PATH) {
  console.log(deployed.base);

  // Reading the file
  fs.readFile(EIP712_PATH, function (err, data) {
    if (err) {
      return console.error(err);
    }

    let context = data.toString();
    // address public constant
    context = context.replace(/_CACHED_DOMAIN_SEPARATOR\s=\s\w*/, "_CACHED_DOMAIN_SEPARATOR = " + deployed.base._CACHED_DOMAIN_SEPARATOR)
    context = context.replace(/_HASHED_NAME\s=\s\w*/, "_HASHED_NAME = " + deployed.base._HASHED_NAME)
    context = context.replace(/_HASHED_VERSION\s=\s\w*/, "_HASHED_VERSION = " + deployed.base._HASHED_VERSION)
    context = context.replace(/_TYPE_HASH\s=\s\w*/, "_TYPE_HASH = " + deployed.base._TYPE_HASH)
    context = context.replace(/_CACHED_CHAIN_ID\s=\s\w*/, "_CACHED_CHAIN_ID = " + deployed.base._CACHED_CHAIN_ID)
    context = context.replace(/_CACHED_THIS\s=\s\w*/, "_CACHED_THIS = " + deployed.base.dexRouter)

    fs.writeFile(EIP712_PATH, context, (err) => {
      if (err) {
        console.log(err);
      }
    });

    console.log("replace finish !")
  });
}

function replace_univ3_contant(UnxswapRouterPath) {
  console.log(deployed.base);

  if (deployed.base._FF_FACTORY == null || deployed.base._FF_FACTORY == "") {
    console.log("warning: _FF_FACTORY is null!!!!");
    return
  }
  // Reading the file
  fs.readFile(UnxswapRouterPath, function (err, data) {
    if (err) {
      return console.error(err);
    }

    let context = data.toString();
    // address public constant
    context = context.replace(/_FF_FACTORY\s+=\s+0x[0-9a-fA-F]+/, "_FF_FACTORY = " + deployed.base._FF_FACTORY);
    // context = context.replace(/_FF_FACTORY\s=\s\w*/, "_FF_FACTORY = " + deployed.base._FF_FACTORY);
    // if (deployed.base._POOL_INIT_CODE_HASH != null || deployed.base._POOL_INIT_CODE_HASH != "") {
    //   context = context.replace(/_POOL_INIT_CODE_HASH\s=\s\w*/, "_POOL_INIT_CODE_HASH = " + deployed.base._POOL_INIT_CODE_HASH);
    // }
    fs.writeFile(UnxswapRouterPath, context, (err) => {
      if (err) {
        console.log(err);
      }
    });

    console.log("replace finish !")
  });
}

replace_contant(UNXSWAP_ROUTER_PATH);
// replace_pmm_contant(PMMROUTER_PATH);
// replace_pmm_eip712_contant(EIP712_PATH);
replace_univ3_contant(UNIV3_PATH);