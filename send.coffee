nodemailer = require('nodemailer')

config = require './config'

transporter = nodemailer.createTransport('smtp://localhost:2525')

transporter.sendMail config.test.mail, (error, info) ->
  if error
    return console.log(error)
  console.log('Message sent: ' + info.response)
