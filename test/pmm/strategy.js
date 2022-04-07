/**
* strategy.js
* market maker will have to define his own strategy here
*/ 

var getToTokenAmount = function (rfq){
    if (rfq.toTokenAmountMin == 0){

    // toTokenAmountMin will be specified to 0 when there is no requirement of the amount, and 
    // market makers could set up the result according to their own strategy.
        // return 0;
        return 1000 * Math.round(Math.random()*10);
    }else{
        if (Math.round(Math.random()) > 0){
            // we simply returns 1.01 times in the demo    
            return rfq.toTokenAmountMin * 0.99            
        }else{
            // we simply returns 1.01 times in the demo    
            return rfq.toTokenAmountMin * 1.01
        }

    }
}

module.exports = getToTokenAmount;


