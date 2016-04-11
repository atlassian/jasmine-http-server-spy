express = require('express')
q = require('q')
_ = require('lodash')
bodyParser = require('body-parser')
debug = require('debug')('jasmine-http-spy')

doneOrFail = (done, err) ->
    if err then done.fail(err) else done()

getRequestObject = (req) ->
    _.pick req, 'params', 'query', 'body', 'headers', 'originalUrl'

class MockServer
    constructor: (@routes, @httpSpy) ->

    setUpApplication: ->
        @app = express()
        @app.use bodyParser.json()
        @app.use bodyParser.urlencoded({ extended: true })
        @app.use (req, res, next) ->
            res.header("Access-Control-Allow-Origin", "*");
            res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
            next();

        for route in @routes
            debug 'Registering mock endpoint', JSON.stringify(route)
            do (route) =>
                @app[route.method] route.url, (req, res) =>
                    process = @httpSpy[route.handlerName]
                    requestObject = getRequestObject req
                    responseObject = process requestObject

                    resolveRequest = (responseObject) ->
                        statusCode = responseObject.statusCode or 200
                        body = responseObject.body or {}

                        debug "Responding to request: #{route.method} #{req.originalUrl}"
                        debug "Request: \n\t" + JSON.stringify requestObject
                        debug "Response: \n\t" + JSON.stringify responseObject

                        res.status(statusCode).send(body)

                    if _.isFunction responseObject.then
                        responseObject.then resolveRequest, (reason) ->
                            console.error "Returned promise was rejected, do nothing"
                            console.error "Rejection reason was:", reason
                    else
                        resolveRequest(responseObject)


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

        @setUpSpies()
        @server = new MockServer(routes, this)

    setUpSpies: ->
        handlerNames = _.pluck routes, 'handlerName'

        # Default implementation to 404
        for handlerName in handlerNames
            this[handlerName] = jasmine.createSpy "#{name}.#{handlerName}"
            this[handlerName].and.returnValue
                statusCode: 404
                body:
                    message: 'Page not found'

module.exports =
    createSpyObj: (name, routes) -> new JasmineHttpServerSpy(name, routes)
