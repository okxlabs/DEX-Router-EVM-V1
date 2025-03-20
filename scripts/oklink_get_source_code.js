const axios = require('axios');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

// Function to get source code from OKLink API
async function getSourceCode(contractAddress, chainName) {
  try {
    // Mapping of chain names to OKLink chain IDs
    const chainMap = {
      'eth': 'eth',
      'ethereum': 'eth',
      'bsc': 'bsc',
      'binance': 'bsc',
      'polygon': 'polygon',
      'arbitrum': 'arbitrum',
      'optimism': 'optimism',
      'avalanche': 'avax',
      'fantom': 'ftm',
      'base': 'base',
      'linea': 'linea',
      'zksync': 'zksync',
      'scroll': 'scroll',
      'opbnb': 'opbnb',
      'mantle': 'mantle',
      'zora': 'zora'
      // Add more chains as needed
    };
    
    // Convert chain name to OKLink chain ID
    const chainId = chainMap[chainName.toLowerCase()];
    if (!chainId) {
      throw new Error(`Unsupported chain: ${chainName}`);
    }
    
    // API Key - Either use from .env or provide directly
    const apiKey = process.env.OKLINK_API_KEY || 'Your-API-Key-Here';
    
    // Construct API URL using the correct endpoint format
    const apiUrl = `https://www.oklink.com/api/v5/explorer/${chainId}/api`;
    
    // Make the API request
    const response = await axios.get(apiUrl, {
      params: {
        module: 'contract',
        action: 'getsourcecode',
        address: contractAddress
      },
      headers: {
        'Ok-Access-Key': apiKey,
        'Content-Type': 'application/json'
      }
    });
    
    // Check for successful response
    if (response.data && response.data.result && response.data.result.length > 0) {
      const sourceCode = response.data.result[0].SourceCode;
      
      // Create source_code directory if it doesn't exist
      const dirPath = path.join(process.cwd(), 'source_code');
      if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
      }
      
      // Write source code to file
      const fileName = path.join(dirPath, `${chainName}_${contractAddress}.sol`);
      fs.writeFileSync(fileName, sourceCode);
      
      console.log(`Source code saved to ${fileName}`);
      return sourceCode;
    } else {
      console.error('API response:', JSON.stringify(response.data, null, 2));
      throw new Error('Source code not found or API returned an error');
    }
  } catch (error) {
    console.error('Error fetching source code:', error.message);
    if (error.response) {
      console.error('API response:', JSON.stringify(error.response.data, null, 2));
    }
    throw error;
  }
}

// Main function
async function main() {
  // Get command line arguments
  const args = process.argv.slice(2);
  
  if (args.length < 2) {
    console.log('Usage: node oklink_get_source_code.js <CONTRACT_ADDRESS> <CHAIN_NAME>');
    console.log('Example: node oklink_get_source_code.js 0x1234abcd eth');
    console.log('Supported chains: eth/ethereum, bsc/binance, polygon, arbitrum, optimism, etc.');
    process.exit(1);
  }
  
  const contractAddress = args[0];
  const chainName = args[1];
  
  try {
    await getSourceCode(contractAddress, chainName);
  } catch (error) {
    console.error('Failed to get source code');
    process.exit(1);
  }
}

// Run the script
if (require.main === module) {
  main();
}

module.exports = {
  getSourceCode
};
