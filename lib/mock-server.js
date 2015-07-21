(function() {
  var MockServer, _, bodyParser, express, q;

  express = require('express');

  q = require('q');

  _ = require('lodash');

  bodyParser = require('body-parser');

  MockServer = (function() {
    var app, doneOrFail, handlers, port, resetHandlers, routes, server, setUpApplication;

    routes = null;

    port = null;

    server = null;

    app = null;

    handlers = null;

    doneOrFail = function(done, err) {
      if (err) {
        return done.fail(err);
      } else {
        return done();
      }
    };

    resetHandlers = function() {
      var handlerNames;
      handlerNames = _.pluck(routes, 'handlerName');
      handlers = jasmine.createSpyObj('handlers', handlerNames);
      return handlerNames.forEach(function(handlerName) {
        return handlers[handlerName].and.returnValue({
          code: 404,
          body: {
            message: 'Page not found'
          }
        });
      });
    };

    setUpApplication = function() {
      app = express();
      app.use(bodyParser.json());
      return _.each(routes, function(route) {
        console.log('Registering mock endpoint', JSON.stringify(route));
        return app[route.method](route.url, function(req, res) {
          var output;
          output = handlers[route.handlerName](req);
          console.log("Responding to request: " + route.method + " " + req.originalUrl, JSON.stringify(_.pick(req, 'params', 'query', 'body')));
          return res.status(output.code).send(output.body);
        });
      });
    };

    function MockServer(_port, _routes) {
      port = _port;
      routes = _routes;
      if ((routes != null ? routes.length : void 0) > 0) {
        resetHandlers();
      }
    }

    MockServer.prototype.start = function(done) {
      setUpApplication();
      return server = app.listen(port, _.partial(doneOrFail, done));
    };

    MockServer.prototype.stop = function(done) {
      return server.close(_.partial(doneOrFail, done));
    };

    MockServer.prototype.getHandlers = function() {
      return handlers;
    };

    return MockServer;

  })();

  module.exports = MockServer;

}).call(this);
