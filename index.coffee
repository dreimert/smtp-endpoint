SMTPServer = require('smtp-server').SMTPServer
MailParser = require("mailparser").MailParser

SERVER_PORT = 2525
SERVER_HOST = '0.0.0.0'

server = new SMTPServer
  logger: true
  banner: 'Welcome to My Awesome SMTP Server'
  disabledCommands: ['STARTTLS']
  authMethods: ['PLAIN', 'LOGIN', 'CRAM-MD5']
  size: 25 * 1024 * 1024
  authOptional: true
  onAuth: (auth, session, callback) ->
    console.log "onAuth", auth, session, callback
    username = 'testuser'
    password = 'testpass'

    if auth.username is username
      if (auth.method is 'CRAM-MD5' and auth.validatePassword(password)) or auth.password is password
        return callback(null, user: 'userdata')
    return callback(new Error('Authentication failed'))

  onMailFrom: (address, session, callback) ->
    console.log "onMailFrom", address, session

    if /^deny/i.test(address.address)
      return callback(new Error('Not accepted'))
    callback()
    return

  onRcptTo: (address, session, callback) ->
    console.log "onRcptTo", address, session

    if /^deny/i.test(address.address)
      return callback(new Error('Not accepted'))

    if address.address.toLowerCase() is 'almost-full@example.com' and Number(session.envelope.mailFrom.args.SIZE) > 100
      err = new Error('Insufficient channel storage: ' + address.address)
      err.responseCode = 452
      return callback(err)

    if not /sobolef.fr$/i.test(address.address)
      return callback(new Error('Not accepted'))

    callback()
    return

  onData: (stream, session, callback) ->
    console.log "onData"
    stream.pipe(process.stdout)
    stream.on 'end', ->
      if stream.sizeExceeded
        err = new Error('Error: message exceeds fixed maximum message size 25 MB')
        err.responseCode = 552
        return callback(err)
      callback(null, 'Message queued as abcdef')

      mailparser = new MailParser(debug: true)

      mailparser.on "end", (mail_object) ->
        console.log("From:", mail_object.from)
        console.log("Subject:", mail_object.subject)
        console.log("Text body:", mail_object.text)

      stream.pipe mailparser

      return


server.on 'error', (err) ->
  console.error('Error occurred')
  console.error(err)

server.listen(SERVER_PORT, SERVER_HOST)
