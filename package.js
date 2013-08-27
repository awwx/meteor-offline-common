Package.describe({
  summary: "common offline code used by the client and the worker",
  internal: true
});

Package.on_use(function (api) {
  api.use(['coffeescript', 'ejson'], ['client', 'server']);

  // TODO we don't actually use browser-msg when the agent is running
  // in a shared web worker.

  api.use([
    'underscore',
    'random',
    'browser-msg',
    'canonical-stringify'
  ], 'client');

  api.export('Context', ['client', 'server']);
  api.add_files('context.litcoffee', ['client', 'server']);

  api.export('Errors', ['client', 'server']);
  api.add_files('errors.litcoffee', ['client', 'server']);

  api.export('Fanout', ['client', 'server'], {testOnly: true});
  api.add_files('fanout.litcoffee', ['client', 'server']);

  api.export('Result', ['client', 'server']);
  api.add_files('result.litcoffee', ['client', 'server']);

  api.export('Offline', ['client', 'server']);
  api.add_files('offline.litcoffee', ['client', 'server']);

  api.export('broadcast', 'client');
  api.add_files('broadcast.litcoffee', 'client');

  api.export('contains', 'client', {testOnly:true});
  api.add_files('contains.litcoffee', 'client');

  api.add_files(
    [
      'database.litcoffee',
      'windows.litcoffee',
      'model.litcoffee',
      'agent.litcoffee'
    ],
    'client'
  );
});

Package.on_test(function(api) {
  api.use(['coffeescript', 'ejson', 'tinytest', 'offline-common']);

  api.add_files(
    [
      'context-tests.coffee',
      'fanout-tests.coffee',
      'result-tests.coffee',
    ],
    ['client', 'server']
  );

  api.add_files(
    [
      'contains-tests.coffee',
      'test-helpers.coffee',
      'database-tests.coffee',
      'agent-tests.coffee'
    ],
    'client'
  );
});
