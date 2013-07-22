    @Offline or= {}
    {Fanout, Result} = awwx
    broadcast = Offline._broadcast
    {defer} = awwx.Error
    {withContext} = awwx.Context
    db = Offline._database


    Offline._windows = {}
    Offline._windows.windowsAreDead = windowsAreDead = new Fanout()


    now = -> +(new Date())


## Running in a shared web worker

    if Agent?

TODO once we get going we don't need to report that no windows are
dead (we could call `windowsAreDead` only when the `windowIds` array
wasn't empty). But do we need to the first time in order to know that
it's safe to clear out old subscriptions?  For now always call
`windowsAreDead`, even with an empty array.

      deadWindows = (windowIds) ->
        Agent.windowIsDead(windowId) for windowId in windowIds
        windowsAreDead(windowIds)
        return


      checking = false
      lastPing = null
      testingWindows = {}


      Agent.addMessageHandler 'pong', (port, data) ->
        delete testingWindows?[data.windowId]
        return


      checkPongs = ->
        deadWindows(_.keys(testingWindows))
        checking = false
        testingWindows = null


      check = ->
        withContext "window check", ->
          return if checking or lastPing? and now() - lastPing < 9000
          checking = true

          db.transaction((tx) ->
            db.readAllWindowIds(tx)
          )
          .then((windowIds) ->
            testingWindows = {}
            testingWindows[windowId] = true for windowId in Agent.windowIds
            testingWindows[windowId] = true for windowId in windowIds
            lastPing = now()
            for port in Agent.ports
              port.postMessage({msg: 'ping'})
            Meteor.setTimeout checkPongs, 4000
            return
          )
          return


      Meteor.startup ->
        check()
        Meteor.setInterval check, 10000


## Running in a browser window

    else

      Offline._windows.thisWindowId = thisWindowId = Random.id()

      Offline._windows.nowAgent = nowAgent = new Fanout()
      Offline._windows.noLongerAgent = noLongerAgent = new Fanout()

      # nowAgent.listen -> Meteor._debug "now the agent"
      # noLongerAgent.listen -> Meteor._debug "no longer the agent"

TODO not used yet

      unload = ->
        withContext "unload", ->
          broadcast 'goodbye', thisWindowId
          return


TODO old IE?  But will we even be loading this code in a browser that
doesn't have a supported database...?

      window.addEventListener('unload', unload, false)


      testingWindows = null
      lastPing = null
      checking = false


      deadWindows = (deadWindowIds) ->
        withContext "deadWindows", ->
          db.transaction((tx) ->
            db.readAgentWindow(tx)
            .then((agentWindowId) ->
              if not agentWindowId? or _.contains(deadWindowIds, agentWindowId)
                becomeTheAgentWindow(tx)
              else
                Result.completed()
            )
          )
          .then(->
            windowsAreDead(deadWindowIds)
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


TODO if no one is the agent tab, we could become the agent
tab immediately.

      check = ->
        withContext "window check", ->
          return if checking
          checking = true
          db.transaction((tx) ->
            db.readAllWindowIds(tx)
          )
          .then((windowIds) ->
            if lastPing? and now() - lastPing < 9000
              return

            testingWindows = {}
            for windowId in windowIds
              unless windowId is thisWindowId
                testingWindows[windowId] = true
            broadcast 'ping'
            Result.delay(4000).then(-> windowIds)
          )
          .then((windowIds) ->
            deadWindows(_.keys(testingWindows))
          )
          .then(->
            checking = false
          )


      Meteor.startup ->
        withContext "windows startup", ->

          return if Offline._disableStartupForTesting

          if Offline._usingSharedWebWorker

            db.transaction((tx) ->
              db.ensureWindow(tx, thisWindowId)
            )

          else

            broadcast.listen 'ping', ->
              withContext "listen ping", ->
                broadcast 'pong', thisWindowId
                return

            broadcast.listen 'pong', (windowId) ->
              withContext "listen pong", ->
                if testingWindows?
                  delete testingWindows[windowId]
                return

            broadcast.listen 'newAgent', (windowId) ->
              withContext "listen newAgent", ->
                if windowId isnt thisWindowId
                  notTheAgent()
                return

            db.transaction((tx) ->
              db.ensureWindow(tx, thisWindowId)
            )
            .then(->
              check()
              Meteor.setInterval check, 10000
            )
            return
