    Offline = {}


    Offline.isWebWorker =
      Meteor.isClient and
      not window? and not document? and importScripts?
