var AWS = require('aws-sdk')

exports.handler = function(event, context, callback) {
    var dynamodb = new AWS.DynamoDB({ apiVersion: '2012-08-10' })
    dynamodb.scan({ TableName: process.env.TABLENAME }, (err, data) => {
        if (err) {
            return callback(err)
        }
        var response = {
            isBase64Encoded: false,
            statusCode: 200,
            headers: {},
            body: JSON.stringify(data.Items)
        }
        return callback(null, response)
    })
}