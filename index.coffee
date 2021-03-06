SMTPServer = require('smtp-server').SMTPServer
MailParser = require("mailparser").MailParser
fs = require('mz/fs')
path = require 'path'

config = require './config'

server = new SMTPServer
  logger: true
  banner: config.server.banner
  disabledCommands: ['STARTTLS']
  authMethods: ['PLAIN', 'LOGIN', 'CRAM-MD5']
  size: 25 * 1024 * 1024
  authOptional: true
  onAuth: (auth, session, callback) ->
    console.log "onAuth", auth, session, callback

    if auth.username is config.test.user.login
      if(
        (auth.method is 'CRAM-MD5' and auth.validatePassword(password)) or
        auth.password is config.test.user.password
      )
        return callback(null, user: 'userdata')
    return callback(new Error('Authentication failed'))

  onMailFrom: (address, session, callback) ->
    if new RegExp(config.rules.fromDeny, "i").test(address.address)
      return callback(new Error('Not accepted'))
    callback()
    return

  onRcptTo: (address, session, callback) ->
    if not new RegExp(config.rules.toAccept, "i").test(address.address)
      return callback(new Error('Not accepted'))
    callback()
    return

  onData: (stream, session, callback) ->
    mailparser = new MailParser(streamAttachments: true)

    mailparser.on "end", (mail) ->
      filenameJson = path.format
        dir: config.mails.dir
        name: mail.messageId
        ext: ".json"

      content = JSON.stringify(mail, null, 2)

      fs.writeFile filenameJson, content, 'utf8'
      .then ->
        console.log('mail save as ', mail.messageId)
      .catch (err) ->
        console.error "writeFile", err, err.stack

    mailparser.on "attachment", (attachment, mail) ->
      console.log "attachment", attachment, mail
      dirname = path.format
        dir: config.mails.dir
        name: mail.messageId
        ext: ".attachments"

      fs.mkdir(dirname)
      .then ->
        filename = path.format
          dir: dirname
          base: attachment.generatedFileName
        console.log "filename", filename
        fs.writeFile filename, attachment.content
        .then ->
          console.log('attachment save as ', filename)
        .catch (err) ->
          console.error "writeFile::attachment", err, err.stack

    stream.pipe mailparser

    stream.on 'end', ->
      if stream.sizeExceeded
        err = new Error('Error: message exceeds fixed maximum size 25 MB')
        err.responseCode = 552
        return callback(err)
      callback(null, 'Message queued as abcdef')
      return

server.on 'error', (err) ->
  console.error('Error occurred')
  console.error(err)

server.listen(config.server.port, config.server.host)
