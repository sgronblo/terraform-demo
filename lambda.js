var employees = [
    {"UserName":{"S":"Sam"},"Role":{"S":"Development"}},
    {"UserName":{"S":"Ivy"},"Role":{"S":"Design"}},
    {"UserName":{"S":"Jun"},"Role":{"S":"Business"}},
]

exports.handler = function(event, context, callback) {
    callback(null, employees)
}