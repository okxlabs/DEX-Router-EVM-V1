const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
    const [signer] = await ethers.getSigners();

    // Get the DexRouter address
    const dexRouterAddress = deployed.base.newImpl;

    // 1. Basic swap data
    const amount = 10000;
    const orderId = 0;
    const rawData = amount;
    const swapData = ethers.utils.defaultAbiCoder.encode(
        ['uint256', 'uint256'],
        [orderId, rawData]
    );

    // 2. Commission parameters
    const FLAG = "0x22220afc2aaa";
    const rate1 = 100; // 1% (100/10000)
    const rate2 = 200; // 2% (200/10000)

    // Validate total rate doesn't exceed 300 (3%)
    if (rate1 + rate2 > 300) {
        throw new Error("Total commission rate cannot exceed 3%");
    }

    // Commission addresses
    const refererAddress1 = "0x1234567890123456789012345678901234567890";
    const refererAddress2 = "0x2234567890123456789012345678901234567890";

    // Token address (using ETH address as example)
    const ETH_ADDRESS = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

    // 3. Construct commission data
    // Format: flag (6 bytes) + rate (6 bytes) + address (20 bytes)
    function constructCommissionData(rate, address) {
        // Convert rate to hex and pad to 6 bytes
        const rateHex = rate.toString(16).padStart(12, '0');
        return ethers.utils.hexConcat([
            FLAG,
            '0x' + rateHex,
            address
        ]);
    }

    // Construct commission data for both referrers
    const commission2Data = constructCommissionData(rate2, refererAddress2);
    const commission1Data = constructCommissionData(rate1, refererAddress1);

    // Pad token address with zeros (12 bytes + 20 bytes address)
    const paddedTokenAddress = ethers.utils.hexZeroPad(ETH_ADDRESS, 32);

    // 4. Combine all data
    // Format: swap_data + commission2Data + paddedTokenAddress + commission1Data
    const finalCalldata = ethers.utils.hexConcat([
        swapData,
        commission2Data,
        paddedTokenAddress,
        commission1Data
    ]);

    console.log("Sending transaction...");
    console.log("Final calldata:", finalCalldata);

    // Calculate expected commission amounts
    const fromTokenAmount = rawData;
    const commission1Amount = (fromTokenAmount * rate1) / (10000 - rate1 - rate2);
    const commission2Amount = (fromTokenAmount * rate2) / (10000 - rate1 - rate2);

    console.log("Expected commission amounts:");
    console.log("Commission 1:", commission1Amount);
    console.log("Commission 2:", commission2Amount);

    // Prepare the function selector for swapwrap
    const functionSelector = "0x01617fab";

    const txData = functionSelector + finalCalldata.slice(2);
    console.log("Transaction data:", txData);
    value = Math.round(amount + commission1Amount + commission2Amount) + 1;
    // Send transaction using call
    const tx = await signer.sendTransaction({
        to: dexRouterAddress,
        data: txData,
        gasLimit: 1000000, // Adjust gas limit as needed
        value: value
    });

    console.log("Transaction hash:", tx.hash);

    // Wait for the transaction to be mined
    const receipt = await tx.wait();
    console.log("Transaction confirmed in block:", receipt.blockNumber);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });