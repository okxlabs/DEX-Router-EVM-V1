const fs = require("fs");
const deployed = require('../deployed');

const UNXSWAP_ROUTER_PATH = "./contracts/8/UnxswapRouter.sol";

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
      context = context.replace(/_WETH\s=\s\w*/, "_WETH = 0x000000000000000000000000" + deployed.base.wNativeToken.replace("0x", ""))
      context = context.replace(/_APPROVE_PROXY_32\s=\s\w*/, "_APPROVE_PROXY_32 = 0x000000000000000000000000" + deployed.base.tokenApproveProxy.replace("0x", ""))
      context = context.replace(/_WNATIVE_RELAY_32\s=\s\w*/, "_WNATIVE_RELAY_32 = 0x000000000000000000000000" + deployed.base.wNativeRelayer.replace("0x", "")) 

      fs.writeFile(UnxswapRouterPath, context, (err) => {
        if (err) {
          console.log(err);
        }
      });

      console.log("replace finish !")
    });
}

replace_contant(UNXSWAP_ROUTER_PATH);