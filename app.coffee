url = require 'url'
express = require 'express'
ws = require 'ws'
kurento = require 'kurento-client'

urls =
  ws: 'http://0.0.0.0:8080/'
  kurento: 'ws://192.168.1.36:8888/kurento'

app = express()
server = null
wss = null
rooms = {}

uniqID = ->
  id = ''
  possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'

  _.times 16, ->
    id += possible.charAt Math.floor Math.random() * possible.length

  id

joinRoom = (user, room) ->
  unless rooms[room]
    rooms[room] =
      members: []

  rooms[room].members.push user.id
  user.room = room

leaveRoom = (user) ->
  if rooms[user.room]
    index = rooms[user.room].members.indexOf user.id
    rooms[user.room].members.splice index, 1 if index > -1

  delete user.room

initServer = ->
  wsUrl = url.parse urls.ws

  server = app.listen wsUrl.port, ->
    wss = new ws.Server
      server : server
      path : '/call'

addListeners = ->
  wss.on 'connection', (ws) ->
    user =
      id: uniqID()

    ws.on 'error', ->
      leaveRoom user

    ws.on 'close', ->
      leaveRoom user

    ws.on 'message', (message) ->
      message = JSON.parse message

      switch message.type
        when 'join'
          joinRoom user, message.room

        when 'leave'
          leaveRoom user

exports.run = ->
  initServer()

