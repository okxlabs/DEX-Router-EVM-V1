const { task } = require("hardhat/config")
const { expect } = require("chai")
require("dotenv/config");
const { ethers } = require("ethers");
// const {
//   getAggregaotrContractInstance,
//   getSeaportContractInstance,
//   getAlienSwapSeaportContractInstanceInBaseChain,
// } = require("../scripts/regression_test/common/common.js");
// const {
//   getSeaportBuyForETHAdvancesOrder,
//   getAlienSwapBuyForETHAdvancesOrder,
//   getTradeData,
//   getAlienSwapConduitKey,
//   orderHash,
// } = require("../scripts/regression_test/fixture/fixtureCommon.js");

const fs = require("fs")
const shell = require('shelljs');
const path = require("path");

function getTimeStr(){
  //timeStamp = Date.now();
  today = new Date();
  return "【"+today.toString()+"】 ";
}

function getLogName(filePath,timeStamp){
   
    temp = filePath.split("/")
    fileName = temp[temp.length -1]

    temp = fileName.split(".");
    today = new Date();
    if(timeStamp){
         return temp[0] + " " + today.toString();
    }

    return temp[0];
   
}


function loadConfig(path,mode) {
  let urls = new Array();
  let chainNames = new Array();
  

  let content = fs.readFileSync(path);
  
  let tempConfig = JSON.parse(content.toString());
  console.log(tempConfig)
    
  console.log("mode:",mode);
  for(var i=0;i<tempConfig[mode].length;i++){
      let url = hre.config.networks[tempConfig[mode][i]].url;
      urls.push(url);
      let chainName = tempConfig[mode][i];
      chainNames.push(chainName)
  }

  let result = {
    urls:urls,
    chainNames:chainNames,
    cmd:tempConfig['cmd'],
    logPath:tempConfig['logPath'],
    mode:mode
  }
  return result;
}

function loadRedoConfig(path,redoLog) {
  let urls = new Array();
  let chainNames = new Array();
  

  let content = fs.readFileSync(path);
  let tempConfig = JSON.parse(content.toString());
  console.log(tempConfig)

  console.log("redo:",redoLog);
  let redoContent = fs.readFileSync(redoLog);
  let redoJSON = JSON.parse(redoContent.toString());
  mode  = redoJSON.redoMode;
  redoIdx = redoJSON.redoIdx;

    
  console.log("mode:",mode);
  for(var i=0;i<redoIdx.length;i++){
      let url = hre.config.networks[tempConfig[mode][redoIdx[i]]].url;
      urls.push(url);
      let chainName = tempConfig[mode][i];
      chainNames.push(chainName)
  }

  let result = {
    urls:urls,
    chainNames:chainNames,
    cmd:tempConfig['cmd'],
    logPath:tempConfig['logPath'],
    mode:mode
  }
  return result;
}

    async function executeBash(processMap,taskArg){

        //mkdir 
        const tempConfigFilePath = processMap.logPath;
        if(!fs.existsSync(tempConfigFilePath)){
                fs.mkdirSync(tempConfigFilePath, { recursive: true });
            
        }

        urls = processMap.urls;
        chainNames = processMap.chainNames;

        logName = getLogName(taskArg.path,true);
        logPath = tempConfigFilePath + logName + '.log';
        //log
        logContent = 'multi chain start execute!\n'
        const data = fs.writeFileSync(logPath,logContent)

        //temp conf obj:未来扩展用 例如失败重试
        redoIdx = new Array();
        for(var i=0;i<urls.length;i++){
            try{
               
                //log
                fs.appendFileSync(logPath,getTimeStr() + ' test '+ chainNames[i]+ ' start!\n')

                //组装cmd
                //cmd = " npx hardhat run scripts/regression_test/fixture/alien/buyForETH_ERC721_alien.js --network " + chainNames[i]
                cmd = processMap.cmd + chainNames[i]; 
                console.log("cmd:",cmd);

                //log
                fs.appendFileSync(logPath,getTimeStr() + ' cmd: '+ cmd + '\n')
                //execute cmd
                stdResult = await shell.exec(cmd);
                
                if (stdResult.code !== 0) {

                    failedContent = getTimeStr() + ' test '+ chainNames[i]+ ' failed! error:' + stdResult.stderr +" \n";
                    fs.appendFileSync(logPath,failedContent)

                    shell.echo('Error: test ' +  chainNames[i] + ' failed!');

                    redoIdx.push(i);
                    //shell.exit(1);
                } else {
                    fs.appendFileSync(logPath,getTimeStr() + ' test '+ chainNames[i]+ ' success!\n')
                }
                
            

            }catch(e){
                //console.log(e);
                failedContent = getTimeStr() + ' test '+ chainNames[i]+ ' failed!\n' + e.message.toString();
                fs.appendFileSync(logPath,failedContent)

                redoIdx.push(i);
            }
    
        }
  
        if(redoIdx.length>0){

            let content = {
                redoMode : processMap.mode ,
                redoIdx : redoIdx
            }
            let configContent = JSON.stringify(content);

            const data = fs.writeFileSync(tempConfigFilePath+'redo-'+getLogName(taskArg.path,false)+'.json',configContent)

        }


        fs.appendFileSync(logPath,"multi chain execute done!")
        console.log("multi chain execute done!");    
    }

task("redo", "redo failed steps")
    .addParam("path", "path of configration")
    .addParam("redo", "path of redo log")
    //.addParam("step", "step of action") 未来扩展
    .setAction(async (taskArg, hre) => {
     
        let processMap = null;
        try {
            processMap = loadRedoConfig(taskArg.path,taskArg.redo);
            console.log(processMap)
        
        } catch (err) {
            console.log(err);
            console.log("读取配置文件失败!");
            return;
        }

        await executeBash(processMap,taskArg);
    })

task("execute", "console the owner of contract").
    addParam("path", "path of configration").
    addParam("mode","mode of define").
    setAction(
    async (taskArg, hre) => {

        //read config
        let processMap = null;
        try {
            processMap = loadConfig(taskArg.path,taskArg.mode);
            console.log(processMap)
        
        } catch (err) {
            console.log(err);
            console.log("读取配置文件失败!");
            return;
        }


        await executeBash(processMap,taskArg);


    }
)


//npx hardhat execute --path [path] --mode [mode] 
//npx hardhat redo --path [path] --redo [path]

//e.x:
//npx hardhat execute --path 'scripts/regression_test/config/multi-chain-alienswap.json'  --mode 'production_test'
//npx hardhat redo --path 'scripts/regression_test/config/multi-chain-alienswap.json'  --redo 'scripts/out/redo-multi-chain-alienswap.json'

//e.x:
//logPath和cmd必须写
//具体的链的配置根据需要写
// {
//    "logPath":"scripts/out/",
//    "cmd" : " npx hardhat run scripts/regression_test/fixture/alien/buyForETH_ERC721_alien.js --network ",
//    "test":["goerli","basetest"],
//    "pre":["mainnetpre","basepre","lineapre"],
//    "production":["mainnet","base","linea"],
//    "production_test":["base"]

// }