Package.describe({
  summary: "common offline code used by the client and the worker",
  internal: true
});

Package.on_use(function (api) {
  api.use('coffeescript', ['client', 'server']);

  // TODO we don't actually use browser-msg when the agent is running
  // in a shared web worker.

  api.use([
    'browser-msg',
    'canonical-stringify'
  ], 'client');

  api.add_files([
    'context.litcoffee',
    'error.litcoffee',
    'fanout.litcoffee',
    'result.litcoffee',
  ], ['client', 'server']);

  api.add_files([
    'broadcast.litcoffee',
    'contains.litcoffee',
    'database.litcoffee',
    'windows.litcoffee',
    'agent.litcoffee'
  ], 'client');
});

Package.on_test(function(api) {
  api.use('offline-common');
  api.add_files([
    'context-tests.coffee',
    'fanout-tests.coffee',
    'result-tests.coffee'
  ], ['client', 'server']);
  api.add_files([
    'test-helpers.coffee',
    'database-tests.coffee',
    'agent-tests.coffee'
  ], 'client');
});
