const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

task("deploy-upgrade", "Deploys and upgrades the DEX contract")
  .setAction(async (taskArgs, hre) => {
    try {
      const network = hre.network.name;

      // Check balance first
      const [deployer] = await hre.ethers.getSigners();
      const balance = await hre.ethers.provider.getBalance(deployer.address);
      const balanceInEth = hre.ethers.utils.formatEther(balance);

      console.log(`Deployer address: ${deployer.address}`);
      console.log(`Balance: ${balanceInEth} ${network === 'bsc' ? 'BNB' : 'ETH'}`);

      if (parseFloat(balanceInEth) < 0.001) {
        throw new Error(`Insufficient balance. Need at least 0.01 ${network === 'bsc' ? 'BNB' : 'ETH'} to deploy`);
      }

      // Step 1: Run ureplace.js
      console.log("\nStep 1: Running ureplace.js...");
      await hre.run("run", {
        script: "scripts/tools/ureplace.js",
        network: network
      });

      // Step 2: Deploy new implementation
      console.log("\nStep 2: Deploying new implementation...");

      // Import and run the deployment script directly
      const deployDexImp = require('../scripts/deploy_dex_imp');
      const newDexRouterAddress = await deployDexImp();

      if (!newDexRouterAddress) {
        throw new Error("Could not get newly deployed dexRouter address");
      }

      // Step 3: Update base.js with new implementation address
      console.log("\nStep 3: Updating implementation address...");
      const baseBasePath = path.join(process.cwd(), 'scripts/deployed/' + network + '/base.js');
      let baseContent = fs.readFileSync(baseBasePath, 'utf8');

      // Update the newImpl address with the newly deployed address
      baseContent = baseContent.replace(
        /newImpl:\s*["'].*["']/,
        `newImpl: "${newDexRouterAddress}"`
      );

      fs.writeFileSync(baseBasePath, baseContent);
      console.log(`Updated newImpl address to: ${newDexRouterAddress}`);

      // Step 4: Verify contracts
      console.log("\nStep 4: Verifying contracts...");
      await hre.run("run", {
        script: "scripts/verify_etherscan_oklink.js",
        network: network
      });

      console.log("\nDeployment and upgrade process completed successfully!");
    } catch (error) {
      console.error("Error during deployment:", error);
      process.exit(1);
    }
  });
