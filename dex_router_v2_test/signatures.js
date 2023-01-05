const { keccak256, defaultAbiCoder, toUtf8Bytes, solidityPack } = require('ethers/lib/utils')
const { ecsign } = require('ethereumjs-util')

exports.sign = (digest, privateKey) => {
  return ecsign(Buffer.from(digest.slice(2), 'hex'), privateKey)
}

PERMIT_TYPEHASH  = keccak256(
  toUtf8Bytes('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)')
)

  // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
  // bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
DAI_LIKE_PERMIT_TYPEHASH  = keccak256(
  toUtf8Bytes("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)")
)

// Returns the EIP712 hash which should be signed by the user
// in order to make a call to `permit`
exports.getPermitDigest = function getPermitDigest(
  name,
  address,
  chainId,
  approve = {
    owner,
    spender,
    value
  },
  nonce,
  deadline
) {
  const DOMAIN_SEPARATOR = getDomainSeparator(name, address, chainId)
  return keccak256(
    solidityPack(
      ['bytes1', 'bytes1', 'bytes32', 'bytes32'],
      [
        '0x19',
        '0x01',
        DOMAIN_SEPARATOR,
        keccak256(
          defaultAbiCoder.encode(
            ['bytes32', 'address', 'address', 'uint256', 'uint256', 'uint256'],
            [PERMIT_TYPEHASH, approve.owner, approve.spender, approve.value, nonce, deadline]
          )
        ),
      ]
    )
  )
}

exports.getDaiLikePermitDigest = function getDaiLikePermitDigest(
  name,
  address,
  chainId,
  approve = {
    owner,
    spender,
    allowed
  },
  nonce,
  deadline
) {
  const DOMAIN_SEPARATOR = getDomainSeparator(name, address, chainId)
  return keccak256(
    solidityPack(
      ['bytes1', 'bytes1', 'bytes32', 'bytes32'],
      [
        '0x19',
        '0x01',
        DOMAIN_SEPARATOR,
        keccak256(
          defaultAbiCoder.encode(
            ['bytes32', 'address', 'address', 'uint256', 'uint256', 'bool'],
            [DAI_LIKE_PERMIT_TYPEHASH, approve.owner, approve.spender, nonce, deadline, approve.allowed]
          )
        ),
      ]
    )
  )
}

// Gets the EIP712 domain separator
function getDomainSeparator(name, contractAddress, chainId) {
  return keccak256(
    defaultAbiCoder.encode(
      ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
      [
        keccak256(toUtf8Bytes('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')),
        keccak256(toUtf8Bytes(name)),
        keccak256(toUtf8Bytes('1')),
        chainId,
        contractAddress,
      ]
    )
  )
}