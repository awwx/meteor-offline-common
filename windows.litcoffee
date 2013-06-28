    return if @Agent?


    @Offline or= {}
    {Fanout, Result} = awwx
    broadcast = Offline._broadcast
    {defer} = awwx.Error
    {withContext} = awwx.Context
    db = Offline._database


    thisWindowId = Random.id()


    nowAgent = new Fanout()
    noLongerAgent = new Fanout()


    # nowAgent.listen -> Meteor._debug "now the agent"
    # noLongerAgent.listen -> Meteor._debug "no longer the agent"


    Offline._windows = {nowAgent, noLongerAgent, thisWindowId}


TODO not used yet

    unload = ->
      withContext "unload", ->
        broadcast 'goodbye', thisWindowId
        return


TODO old IE?  But will we even be loading this code in a browser that
doesn't have a supported database...?

    window.addEventListener('unload', unload, false)


    windowIdsAtLastCheck = null


    lastPing = null


    deadWindows = (deadWindowIds) ->
      withContext "deadWindows", ->
        db.transaction((tx) ->
          (if deadWindowIds.length > 0
             broadcast 'deadWindows', deadWindowIds
             db.deleteWindows(tx, deadWindowIds)
           else
             Result.completed()
          )
          .then(->
            Result.join([
              db.readWindowIds(tx)
              db.readAgentWindow(tx)
            ])
          )
          .then(([windowIds, agentWindowId]) ->
            (unless agentWindowId? and _.contains(windowIds, agentWindowId)
               becomeTheAgentWindow(tx)
               .then(-> thisWindowId)
             else
               Result.completed(agentWindowId)
            )
            .then((agentWindowId) ->
              # updateWindows windowIds, agentWindowId
              return
            )
          )
        )


    currentlyTheAgent = false

    Offline._windows.currentlyTheAgent = -> currentlyTheAgent

    becomeTheAgentWindow = (tx) ->
      withContext "becomeTheAgentWindow", ->
        currentlyTheAgent = true
        defer -> nowAgent()
        db.writeAgentWindow(tx, thisWindowId)
        .then(->
          broadcast 'newAgent', thisWindowId
          return
        )


    notTheAgent = ->
      withContext "notTheAgent", ->
        return unless currentlyTheAgent
        currentlyTheAgent = false
        noLongerAgent()
        return


    now = -> +(new Date())


    checking = false


TODO if no one is the agent tab, we could become the agent
tab immediately.

    check = ->
      withContext "window check", ->
        return if checking
        checking = true
        db.transaction((tx) ->
          db.readWindowIds(tx)
        )
        .then((windowIds) ->
          if lastPing? and now() - lastPing < 9000
            return

          windowIdsAtLastCheck = {}
          for windowId in windowIds
            unless windowId is thisWindowId
              windowIdsAtLastCheck[windowId] = true
          broadcast 'ping'
          Result.delay(4000).then(-> windowIds)
        )
        .then((windowIds) ->
          dead = []
          for windowId in windowIds
            if windowIdsAtLastCheck[windowId]
              dead.push windowId
          deadWindows(dead)
        )
        .then(->
          checking = false
        )


    Meteor.startup ->
      withContext "windows startup", ->

        return if (Offline._disableStartupForTesting or
                   Offline._usingSharedWebWorker)

        broadcast.listen 'ping', ->
          withContext "listen ping", ->
            broadcast 'pong', thisWindowId
            return

        broadcast.listen 'pong', (windowId) ->
          withContext "listen pong", ->
            if windowIdsAtLastCheck?
              delete windowIdsAtLastCheck[windowId]
            return

        broadcast.listen 'newAgent', (windowId) ->
          withContext "listen newAgent", ->
            if windowId isnt thisWindowId
              notTheAgent()
            return

        db.transaction((tx) ->
          db.ensureWindow(tx, thisWindowId)
        )
        .then(-> check())
        Meteor.setInterval check, 10000
        return
