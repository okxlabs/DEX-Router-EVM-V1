/*
* cancel_from_server.js
* a demo that market makers could use to cancel quotes from aggregation server
*/

const http = require("http");
const fs = require("fs");
const { AGGREGATION_SERVER_URL } = require("../constants");
const { getPushInfosToBeSigned, multipleQuotes } = require('../quoter');
const port = 8443;

const httpRequest = http.request({
        hostname: AGGREGATION_SERVER_URL,
        // path: '/priapi/v1/dx/public/multi/test/push',
        path: '/pushQuotes',
        method: "POST",
        port: port,
        json: true,
        headers:{
            "content-type": "application/json",
        }
    },
    (res) => {
      console.log(`STATUS: ${res.statusCode}`);
      console.log(`HEADERS: ${JSON.stringify(res.headers)}`);
      res.setEncoding('utf8');
      res.on('data', (chunk) => {
        console.log(`BODY: ${chunk}`);
      });
      res.on('end', () => {
        console.log('No more data in response.')
      })
    });

fs.readFile("./cancel_from_server_data.json", (err, cancel_data) =>{
  if (err) {
    console.log(err);
  }else{
    console.log("stringfy", JSON.parse(cancel_data));
    httpRequest.write(cancel_data);
    // console.log("cancel_data", cancel_data);

    httpRequest.on('error', err => {
        console.log("request error:", err);
    });

    httpRequest.end();
  };
});
