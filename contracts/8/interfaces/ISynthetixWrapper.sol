/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface ISynthetixWrapper {

  function token() external view returns (address);

  // token => stoken
  function mint(uint amount) external;

  // stoken => token
  function burn(uint amount) external;

}

interface ISynthetixEtherWrapper {

  // token => stoken
  function mint(uint amount) external;

  // stoken => token
  function burn(uint amount) external;

  function capacity() external view returns (uint);

  function getReserves() external view returns (uint);
}