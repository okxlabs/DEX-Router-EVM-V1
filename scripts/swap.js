const { ethers } = require("hardhat");

async function main() {  
  usdt = await ethers.getContractAt(
    'MockERC20',
    '0x55d398326f99059ff775485246999027b3197955'
  )
  weth = await ethers.getContractAt(
    "MockERC20",
    '0x2170ed0880ac9a755fd29b2688956bd959f933f8'
  )
  wbnb = await ethers.getContractAt(
    "MockERC20",
    '0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c'
  )
  dot = await ethers.getContractAt(
    "MockERC20",
    '0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402'
  )
  tokenApprove = await ethers.getContractAt(
    "TokenApprove",
    "0xA5C4b7A0ACA42FdCd6274077f8Db3c8f0030F77D"
  );
  dexRouteProxy = await ethers.getContractAt(
    "DexRouteProxy",
    "0xAc422f1Cb5E1b89A43ff049fC4977533226dAA18"
  );

  fromTokenAmount = ethers.utils.parseEther('0.79374371');
  minReturnAmount = ethers.utils.parseEther('0');
  deadLine = 2000000000;

  data = [
    [
      [
        [
          [
            "0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402"
          ],
          [
            "0x55d398326f99059fF775485246999027B3197955"
          ],
          [
            "1525406350000000000"
          ]
        ]
      ],
      [
        [
          [
            "0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402"
          ],
          [
            "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
          ],
          [
            "1525406350000000000"
          ]
        ],
        [
          [
            "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
          ],
          [
            "0x55d398326f99059fF775485246999027B3197955"
          ],
          [
            "0"
          ]
        ]
      ]
    ],
    [
      [
        [
          [
            [
              "0xe98300a7784599122Ae792F2A5Dcdb33e0318540"
            ]
          ],
          [
            [
              "0xff44e10662e1cd4f7afe399144636c74b0d05d80"
            ]
          ],
          [
            [
              "0xff44e10662e1cd4f7afe399144636c74b0d05d80",
              "0xf1E4C96062CC04B4656Eeed4176539843df88678"
            ]
          ],
          [
            [
              10000
            ]
          ],
          [
            [
              0
            ]
          ],
          [
            [
              0
            ]
          ]
        ]
      ],
      [
        [
          [
            [
              "0xe98300a7784599122Ae792F2A5Dcdb33e0318540"
            ]
          ],
          [
            [
              "0xbdade5c2c966ee5558d2e0bdd3d9276bea2c6007"
            ]
          ],
          [
            [
              "0xbdade5c2c966ee5558d2e0bdd3d9276bea2c6007",
              "0xAc422f1Cb5E1b89A43ff049fC4977533226dAA18"
            ]
          ],
          [
            [
              10000
            ]
          ],
          [
            [
              1
            ]
          ],
          [
            [
              0
            ]
          ]
        ],
        [
          [
            [
              "0xda29cD88D7db8FA023213DC448Da6AbEF9df5029"
            ]
          ],
          [
            [
              "0x16b9a82891338f9ba80e2d6970fdda79d1eb0dae"
            ]
          ],
          [
            [
              "0x16b9a82891338f9ba80e2d6970fdda79d1eb0dae",
              "0xf1E4C96062CC04B4656Eeed4176539843df88678"
            ]
          ],
          [
            [
              10000
            ]
          ],
          [
            [
              0
            ]
          ],
          [
            [
              0
            ]
          ]
        ]
      ]
    ]
  ]

  // r = await wbnb.approve(tokenApprove.address, ethers.utils.parseEther('100000000'));
  // console.log(r);
  r = await dexRouteProxy.callStatic.mutliSwap(
    dot.address,
    usdt.address,
    fromTokenAmount,
    minReturnAmount,
    deadLine,
    data[0],
    data[1]
  );
  console.log("" + r)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
