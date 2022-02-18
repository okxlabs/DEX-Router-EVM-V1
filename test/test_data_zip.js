const { ethers, upgrades } = require('hardhat')
const { expect } = require('chai')

describe("bytes data serialize test", function() {

  before(async function() {
    [owner, alice, bob, liquidity] = await ethers.getSigners();

    SerializeTest = await ethers.getContractFactory("SerializeTest");
    serializeTest = await upgrades.deployProxy(SerializeTest, []);
    await serializeTest.deployed();
  });

  it("address serialize test", async () => {
    serializeAddress = await serializeTest.serializeAddress([owner.address, alice.address, bob.address]);
    // 16 + 40 + 40 + 40 => (8 + 20 + 20 + 20 + 3 + '0x') = 144
    console.log(serializeAddress);
    // It contains the 0x that needs to be removed
    expect(serializeAddress.length).to.be.eq(144);
    // 0300000000000000
    // 14 f39fd6e51aad88f6f4ce6ab8827279cfffb92266
    // 14 70997970c51812dc3a010c7d01b50e0d17dc79c8
    // 14 3c44cdddb6a900fa2b585dd299e03d12fa4293bc
    deserializeAddress = await serializeTest.deserializeAddress(serializeAddress);
    expect(deserializeAddress.length).to.eq(3);
  });

  it("param serialize test", async () => {
    toContract = await serializeTest.serializeAddress([owner.address])
    methods = await serializeTest.serializeAddress([alice.address])
    txData = await serializeTest.serializeAddress([bob.address])
    zipAddressData = await serializeTest.crossChain(1, toContract, methods, txData);
    expect(zipAddressData.length).to.eq(372)
  });

  it("param serialize base param", async () => {
    serializeBaseParam = await serializeTest.serializeBaseParam(
      alice.address,
      bob.address,
      ethers.utils.parseEther('10'),
      ethers.utils.parseEther('5'),
      2000000000
    );
    console.log(serializeBaseParam);

    deserializeBaseParam = await serializeTest.deserializeBaseParam(
      serializeBaseParam
    );
    expect(deserializeBaseParam[0]).to.be.eq(alice.address);
    expect(deserializeBaseParam[1]).to.be.eq(bob.address);
    expect(deserializeBaseParam[2]).to.be.eq(ethers.utils.parseEther('10'));
    expect(deserializeBaseParam[3]).to.be.eq(ethers.utils.parseEther('5'));
    expect(deserializeBaseParam[4]).to.be.eq(2000000000);
  })
});
