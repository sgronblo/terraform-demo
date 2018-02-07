var employees = [
    {"UserName":{"S":"Sam"},"Role":{"S":"Development"}},
    {"UserName":{"S":"Ivy"},"Role":{"S":"Design"}},
    {"UserName":{"S":"Jun"},"Role":{"S":"Business"}},
]

exports.handler = function(event, context, callback) {
    var response = {
        isBase64Encoded: false,
        statusCode: 200,
        headers: {},
        body: JSON.stringify(employees)
    }
    callback(null, response)
}