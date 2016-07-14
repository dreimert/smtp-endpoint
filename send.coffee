nodemailer = require('nodemailer')

transporter = nodemailer.createTransport('smtp://localhost:2525')

mailOptions =
  from: '"test 👥" <damien.reimert@gmail.com>',
  to: 'test@testmail.sobolef.fr',
  subject: 'Hello ✔',
  text: 'Hello world 🐴',
  html: '<b>Hello world 🐴</b>'

transporter.sendMail mailOptions, (error, info) ->
  if error
    return console.log(error)
  console.log('Message sent: ' + info.response)
