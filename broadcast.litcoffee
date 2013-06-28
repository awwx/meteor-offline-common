    {Fanout} = awwx
    {defer} = awwx.Error
    {withContext} = awwx.Context


The shared web worker uses messaging instead of broadcast.

    return if @Agent?


    topics = {}

    topic = (messageTopic) ->
      topics[messageTopic] or= new Fanout()

    onMessage = (messageTopic, args) ->
      withContext "received broadcast msg #{messageTopic}", ->
        topic(messageTopic)(args...)
        return
      return

    Meteor.startup ->
      unless Offline?._usingSharedWebWorker
        Meteor.BrowserMsg.listen
          '/awwx/offline-data/broadcast': (messageTopic, args) ->
            onMessage messageTopic, args
            return
      return

    broadcast = (messageTopic, args...) ->
      Meteor.BrowserMsg.send('/awwx/offline-data/broadcast', messageTopic, args)
      return

    broadcast.includingSelf = (messageTopic, args...) ->
      Meteor.BrowserMsg.send('/awwx/offline-data/broadcast', messageTopic, args)
      defer -> topic(messageTopic)(args...)
      return

    broadcast.listen = (messageTopic, callback) ->
      topic(messageTopic).listen callback
      return

    (@Offline or= {})._broadcast = broadcast
