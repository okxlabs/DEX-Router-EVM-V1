const { upgrades } = require('hardhat');

async function main() {
  const instance = await upgrades.admin.getInstance();
  console.log(await instance.getProxyAdmin("0x3b3ae790Df4F312e745D270119c6052904FB6790"));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });