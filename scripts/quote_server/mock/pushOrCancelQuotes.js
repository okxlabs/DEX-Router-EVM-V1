

var pushOrCancelQuotes = function (quotes){
    let res = [];
    for (let i = 0; i < quotes.length; i++){
        res[i] = true;
    }
    return res;
}

module.exports = {pushOrCancelQuotes};