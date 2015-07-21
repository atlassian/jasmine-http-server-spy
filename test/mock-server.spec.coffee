MockServer = require('../src/mock-server')
request = require('request')
q = require('q')
_ = require('lodash')

parseBodyAsJson = (responseAndBody) ->
    try
        return q(
            response: responseAndBody.response
            body: JSON.parse responseAndBody.body)
    catch e
        return q.reject new Error('Unable to parse body as json. Body: ' + responseAndBody.body)

makeRequest = (url, {body, headers}={}) ->
    deferred = q.defer()

    requestOptions =
        method: 'POST'
        url: url
        body: body and JSON.stringify(body) or ''
        headers: _.merge(headers or {}, 'content-type': 'application/json')

    request requestOptions, (error, response, body) ->
        if error
            deferred.reject error
        else
            deferred.resolve
                response: response
                body: body

    return deferred.promise

describe 'mock server', ->
    describe 'with no routes defined', ->
        beforeEach (done) ->
            @mockServer = new MockServer(8082, [])
            @handlers = @mockServer.getHandlers()
            @mockServer.start(done)

        afterEach (done) ->
            @mockServer.stop(done)

        it 'should still response with 404', (done) ->
            makeRequest('http://localhost:8082/something-non-existent')
                .then (result) ->
                    expect(result.response.statusCode).toBe 404
                .then done, done.fail

#    describe 'port is taken', ->
#        it 'a', (done) ->
#            mockServer = new MockServer(8082, [])
#
#            mockServer.start ->
#                console.log 'mockServer.start'
#                anotherServer = new MockServer(8082, [])
#                fakeDone = ->
#                    console.log 'fakeDone'
#                    mockServer.stop ->
#                        done.fail 'Done wasn\'t expected to be called'
#
#                fakeDone.fail = (e) ->
#                    console.log 'fakeDone.fail'
#                    mockServer.stop ->
#                        console.log 'error, its ok ', e
#                        done()
#
#                anotherServer.start fakeDone

    describe 'with routes defined', ->
        beforeAll ->
            @routes = [
                {
                    method: 'post'
                    url: '/mockService/users'
                    handlerName: 'handlePostUsers'
                }
                {
                    method: 'get'
                    url: '/mockService/users'
                    handlerName: 'handleGetUsers'
                }
            ]

        beforeEach (done) ->
            @mockServer = new MockServer(8082, @routes)
            @handlers = @mockServer.getHandlers()
            @mockServer.start(done)

        afterEach (done) ->
            @mockServer.stop(done)

        it 'should return 404 for undefined handlers', (done) ->
            makeRequest('http://localhost:8082/mockService/users')
                .then(parseBodyAsJson)
                .then (result) ->
                    expect(result.response.statusCode).toBe 404
                    expect(result.body).toEqual message: 'Page not found'
                .then done, done.fail

        it 'should return registered output', (done) ->
            @handlers.handlePostUsers.and.returnValue
                code: 200
                body:
                    firstName: 'John'

            makeRequest('http://localhost:8082/mockService/users', body: property: 'anythingHere')
                .then(parseBodyAsJson)
                .then (result) ->
                    expect(result.response.statusCode).toBe 200
                    expect(result.body).toEqual firstName: 'John'
                .then done, done.fail

        it 'should return different outputs when use call fake', (done) ->
            @handlers.handlePostUsers.and.callFake (req) ->
                code: 200
                body:
                    users:
                        if _.isEqual(req.body, query: 'Jo*')
                            [firstName: 'John']
                        else if _.isEqual(req.body, query: 'Pet*')
                            [
                                {firstName: 'Pet'}
                                {firstName: 'Peter'}
                            ]
                        else if _.isMatch(req.headers, special: 'all')
                            [
                                {firstName: 'Pet'}
                                {firstName: 'Peter'}
                                {firstName: 'John'}
                            ]
                        else if _.isMatch(req.headers, special: 'friends')
                            [firstName: 'John']
                        else
                            []

            req1 = makeRequest( 'http://localhost:8082/mockService/users', body: query: 'Jo*')
                    .then(parseBodyAsJson)
            req2 = makeRequest('http://localhost:8082/mockService/users', body: query: 'Pet*')
                    .then(parseBodyAsJson)
            req3 = makeRequest('http://localhost:8082/mockService/users', headers: special: 'all')
                    .then(parseBodyAsJson)
            req4 = makeRequest('http://localhost:8082/mockService/users', headers: special: 'friends')
                    .then(parseBodyAsJson)
            req5 = makeRequest('http://localhost:8082/mockService/users',
                        body: { random: Math.random() }, headers: { random: Math.random() })
                    .then(parseBodyAsJson)

            q.all([req1, req2, req3, req4, req5])
                .spread (res1, res2, res3, res4, res5) ->
                    expect(res1.response.statusCode).toBe 200
                    expect(res2.response.statusCode).toBe 200
                    expect(res3.response.statusCode).toBe 200
                    expect(res4.response.statusCode).toBe 200
                    expect(res5.response.statusCode).toBe 200
                    expect(res1.body).toEqual users: [firstName: 'John']
                    expect(res2.body).toEqual users: [{firstName: 'Pet'}, {firstName: 'Peter'}]
                    expect(res3.body).toEqual users: [{firstName: 'Pet'}, {firstName: 'Peter'}, {firstName: 'John'}]
                    expect(res4.body).toEqual users: [firstName: 'John']
                    expect(res5.body).toEqual users: []
                .then done, done.fail
