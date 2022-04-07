const express = require('express');
const { pushOrCancelQuotes } = require('./pushOrCancelQuotes.js');
const port = 8443;
const server = express();

server.use(express.json());

server.post('/pushQuotes', (req, res) => {
    let rfqs = req.body;

    console.log("rfqs", rfqs);

    let result = pushOrCancelQuotes(rfqs);

    console.log("result", result);
    
    res.send(result);
});

server.listen(port, () => console.log(`Example app listening on port ${port}!`));