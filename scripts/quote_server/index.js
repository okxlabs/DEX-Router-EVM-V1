/**
*  index.js
*  This is the demo for market makers showing how to participate in dex swap with their private liquidity
*/

const express = require('express');
const { getPullInfosToBeSigned, multipleQuotes, getDomainSeparator } = require('./quoter');

const port = 8000;
const server = express();

server.use(express.json());

//todo market maker may define request control here if they want

server.post('/RFQ', (req, res) => {
    // rfq will be an array json type file data with specified structure of request for quotes
    let rfq = req.body;

    console.log(rfq);

    // market maker will sign each of the quote and return an other array json type data with specified structure
    let result = getPullInfosToBeSigned(rfq);
    let filledRfq = multipleQuotes(result.pullInfosToBeSigned, result.chainId);

    console.log("filledRfq: ", filledRfq);
    
    res.send(filledRfq);
})

server.listen(port, () => console.log(`Quote server listening on port ${port}!`))