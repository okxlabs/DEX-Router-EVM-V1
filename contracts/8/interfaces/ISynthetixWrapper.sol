pragma solidity ^0.8.0;
pragma abicoder v2;

interface ISynthetixWrapper {

  function token() external view returns (address);

  function mint(uint amount) external;

  function burn(uint amount) external;

}

interface ISynthetixEtherWrapper {

  function mint(uint amount) external;

  function burn(uint amount) external;

  function capacity() external view returns (uint);

  function getReserves() external view returns (uint);
}
