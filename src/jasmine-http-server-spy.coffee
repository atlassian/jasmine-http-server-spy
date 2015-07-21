express = require('express')
q = require('q')
_ = require('lodash')
bodyParser = require('body-parser')

doneOrFail = (done, err) ->
    if err then done.fail(err) else done()

getRequestObject = (req) ->
    _.pick req, 'params', 'query', 'body', 'headers', 'originalUrl'

class MockServer
    constructor: (@routes, @httpSpy) ->

    setUpApplication: ->
        @app = express()
        @app.use bodyParser.json()

        for route in @routes
            console.log 'Registering mock endpoint', JSON.stringify(route)

            @app[route.method] route.url, (req, res) =>
                processRequest = @httpSpy[route.handlerName]
                requestObject = getRequestObject req
                responseObject = processRequest requestObject

                console.log "Responding to request: #{route.method} #{req.originalUrl}",
                    JSON.stringify requestObject

                res.status(responseObject.code).send responseObject.body

    start: (@port, done) ->
        @setUpApplication()
        @server = @app.listen @port, _.partial(doneOrFail, done)

    stop: (done) ->
        @server.close _.partial(doneOrFail, done)


class JasmineHttpServerSpy
    routes = null
    name = null

    constructor: (_name, _routes) ->
        routes = _routes
        name = _name
        if not routes or routes.length is 0
            throw new Error("Routes list should be provided")

        setUpSpies.call(this)
        @server = new MockServer(routes, this)

    setUpSpies = ->
        handlerNames = _.pluck routes, 'handlerName'

        # Default implementation to 404
        for handlerName in handlerNames
            this[handlerName] = jasmine.createSpy "#{name}.#{handlerNames}"
            this[handlerName].and.returnValue
                code: 404
                body:
                    message: 'Page not found'

module.exports =
    createSpyObj: (name, routes) -> new JasmineHttpServerSpy(name, routes)
