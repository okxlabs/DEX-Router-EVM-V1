/*
* pusher.js
* a demo that market makers could use to push quotes to aggregation server
*/

const http = require("http");
const fs = require("fs");
const { AGGREGATION_SERVER_URL } = require("../constants");
const { getPushInfosToBeSigned, multipleQuotes } = require('../quoter');
const port = 8443;

const httpRequest = http.request({
        hostname: AGGREGATION_SERVER_URL,
        path: '/priapi/v1/dx/public/multi/test/push',
        method: "POST",
        port: port,
        json: true,
        headers:{
            "content-type": "application/json",
        }
    },
    function(error, response, body){
        if(!error && response.statusCode == 200){
            console.log(body);
        }
    });

fs.readFile("./pushdata.json", (err, data) =>{
  if (err) {
    console.log(err);
  }else{
    let source_data = getPushInfosToBeSigned(JSON.parse(data));
    let push_data = JSON.stringify(multipleQuotes(source_data.pushInfosToBeSigned, source_data.chainId));
    httpRequest.write(push_data);
    console.log("push_data", push_data);

    httpRequest.on('error', err => {
        console.log(err);
    });

    httpRequest.end();
    console.log("push success");
  };
});