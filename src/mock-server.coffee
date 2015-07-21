express = require('express')
q = require('q')
_ = require('lodash')
bodyParser = require('body-parser')

class MockServer
    routes = null
    port = null
    server = null
    app = null
    handlers = null

    doneOrFail = (done, err) ->
        if err
            done.fail(err)
        else
            done()

    resetHandlers = ->
        handlerNames = _.pluck routes, 'handlerName'
        handlers = jasmine.createSpyObj('handlers', handlerNames)

        # Default implementation to 404
        handlerNames.forEach (handlerName) ->
            handlers[handlerName].and.returnValue
                code: 404
                body:
                    message: 'Page not found'

    setUpApplication = ->
        app = express()
        app.use bodyParser.json()

        _.each routes, (route) ->
            console.log 'Registering mock endpoint', JSON.stringify(route)
            app[route.method] route.url, (req, res) ->
                output = handlers[route.handlerName](req)
                console.log "Responding to request: #{route.method} #{req.originalUrl}",
                    JSON.stringify _.pick(req, 'params', 'query', 'body')
                res.status(output.code).send output.body

    constructor: (_port, _routes) ->
        port = _port
        routes = _routes

        resetHandlers() if routes?.length > 0

    start: (done) ->
        setUpApplication()
        server = app.listen port, _.partial doneOrFail, done
#        server.on 'error', (err) -> done.fail err

    stop: (done) ->
        server.close _.partial doneOrFail, done

    getHandlers: -> handlers

module.exports = MockServer
