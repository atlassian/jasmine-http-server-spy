jasmineHttpServerSpy = require('../src/jasmine-http-server-spy')
request = require('request')
q = require('q')
_ = require('lodash')

parseBodyAsJson = (responseAndBody) ->
    try
        return q(
            response: responseAndBody.response
            body: JSON.parse responseAndBody.body)
    catch e
        return q.reject new Error('Unable to parse body as json. Body: ' + JSON.stringify(responseAndBody.body))

makeRequest = (url, options={}) ->
    deferred = q.defer()
    defaults =
        method: 'POST'
        headers:
            'Content-Type': if _.isObject options.body then 'application/json' else 'text/html'
        url: url

    requestOptions = _.defaultsDeep({}, options, defaults)
    requestOptions.body = JSON.stringify requestOptions.body if _.isObject options.body

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
        it 'should blow up', ->
            try
                jasmineHttpServerSpy.createSpyObj('mockServer', [])
                fail 'Exception was expected'
            catch e

    describe 'with routes defined', ->

        beforeEach (andDone) ->
            @httpSpy = jasmineHttpServerSpy.createSpyObj('mockServer', [
                {
                    method: 'post'
                    url: '/mockService/users'
                    handlerName: 'postUsers'
                }
                {
                    method: 'get'
                    url: '/mockService/users'
                    handlerName: 'getUsers'
                }
            ])
            @httpSpy.server.start 8082, andDone

        afterEach (andDone) ->
            @httpSpy.server.stop andDone

        beforeEach ->
            @httpSpy.postUsers.calls.reset()
            @httpSpy.getUsers.calls.reset()

        it 'should return 200 when has body only', (done) ->
            @httpSpy.postUsers.and.returnValue
                body:
                    firstName: 'John'

            makeRequest(
                'http://localhost:8082/mockService/users',
                body:
                    property: 'anythingHere')
            .then(parseBodyAsJson)
            .then (result) ->
                expect(result.response.statusCode).toBe 200
            .then done, done.fail

        it 'should return empty body when body is not defined', (done) ->
            @httpSpy.postUsers.and.returnValue statusCode: 200

            makeRequest(
                'http://localhost:8082/mockService/users',
                body:
                    property: 'anythingHere')
            .then(parseBodyAsJson)
            .then (result) ->
                expect(result.response.statusCode).toBe 200
                expect(result.body).toEqual({})
            .then done, done.fail

        it 'should wait for promise to resolve', (done) ->
            deferred = q.defer()
            @httpSpy.postUsers.and.returnValue deferred.promise

            makeRequest(
                'http://localhost:8082/mockService/users',
                body:
                    property: 'anythingHere')
            .then(parseBodyAsJson)
            .then (result) ->
                expect(result.response.statusCode).toBe 200
                expect(result.body).toEqual firstName: 'John'
            .then done, done.fail

            deferred.resolve({
                statusCode: 200,
                body:
                    firstName: 'John'
            })

        it 'should return 404 for undefined handlers', (done) ->
            makeRequest('http://localhost:8082/mockService/users')
                .then(parseBodyAsJson)
                .then (result) ->
                    expect(result.response.statusCode).toBe 404
                    expect(result.body).toEqual message: 'Page not found'
                .then done, done.fail

        it 'should return registered output', (done) ->
            @httpSpy.postUsers.and.returnValue
                statusCode: 200
                body:
                    firstName: 'John'

            makeRequest('http://localhost:8082/mockService/users', body: property: 'anythingHere')
                .then(parseBodyAsJson)
                .then (result) ->
                    expect(result.response.statusCode).toBe 200
                    expect(result.body).toEqual firstName: 'John'
                .then done, done.fail

        it 'should parse post bodies encoded as json', (done) ->
            body = property1: 'value1'
            headers = 'Content-Type': 'application/json'
            makeRequest('http://localhost:8082/mockService/users', {body: body, headers: headers})
                .then (result) =>
                    expect(@httpSpy.postUsers).toHaveBeenCalledWith(jasmine.objectContaining(
                        body:
                            property1: 'value1'
                    ))
                .then done, done.fail

        it 'should parse post bodies encoded as x-www-form-urlencoded', (done) ->
            form = property1: 'value1'
            headers = 'Content-Type': 'application/x-www-form-urlencoded'
            makeRequest('http://localhost:8082/mockService/users', {form: form, headers: headers})
                .then (result) =>
                    expect(@httpSpy.postUsers).toHaveBeenCalledWith(jasmine.objectContaining(
                        body:
                            property1: 'value1'
                    ))
                .then done, done.fail

        it 'should return different outputs when use call fake', (done) ->
            @httpSpy.postUsers.and.callFake (req) ->
                statusCode: 200
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

            q.all([req1, req2, req3, req4, req5]).spread (res1, res2, res3, res4, res5) =>
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

                expect(@httpSpy.postUsers).toHaveBeenCalled()
                expect(@httpSpy.postUsers.calls.count()).toBe(5)

            .then done, done.fail

        it 'should have query parameters in handler input', (done) ->
            @httpSpy.getUsers.and.callFake (req) ->
                expect(req.query.q).toBe "Peter Pen"
                done()
                return {statusCode: 200}
            makeRequest('http://localhost:8082/mockService/users?q=Peter Pen', method: 'GET').fail done.fail

        it 'should have empty query parameters in handler input if no query parameters used', (done) ->
            @httpSpy.getUsers.and.callFake (req) ->
                expect(req.query).not.toBeUndefined()
                expect(_.keys(req.query).length).toBe 0
                done()
                return {statusCode: 200}
            makeRequest('http://localhost:8082/mockService/users', method: 'GET').fail done.fail

        it 'should have originalUrl in handler input', (done) ->
            @httpSpy.getUsers.and.callFake (req) ->
                expect(req.originalUrl).toBe '/mockService/users?something'
                done()
                return {statusCode: 200}
            makeRequest('http://localhost:8082/mockService/users?something', method: 'GET').fail done.fail

        expectCrossOriginResponseHeadersToBeReturned = (response) ->
            expect(response.headers['access-control-allow-origin']).toBeDefined()
            expect(response.headers['access-control-allow-origin']).toBe '*'
            expect(response.headers['access-control-allow-headers']).toBeDefined()
            expect(response.headers['access-control-allow-headers']).toBe 'Origin, X-Requested-With, Content-Type, Accept'

        it 'should return cross origin response headers for get requests', (done) ->
            @httpSpy.getUsers.and.returnValue
                statusCode: 200

            makeRequest('http://localhost:8082/mockService/users', method: 'GET')
                .then (result) ->
                    expect(result.response.statusCode).toBe 200
                    expectCrossOriginResponseHeadersToBeReturned result.response
                .then done, done.fail

        it 'should return cross origin response headers for post requests', (done) ->
            @httpSpy.postUsers.and.returnValue
                statusCode: 200

            makeRequest('http://localhost:8082/mockService/users', method: 'POST')
                .then (result) ->
                    expect(result.response.statusCode).toBe 200
                    expectCrossOriginResponseHeadersToBeReturned result.response
                .then done, done.fail

        it 'should return response headers defined in mock return value', (done) ->
            @httpSpy.getUsers.and.returnValue
                statusCode: 200,
                headers:
                    'Content-Type': 'application/xml; charset=utf-8'

            makeRequest('http://localhost:8082/mockService/users', method: 'GET')
                .then (result) ->
                    expect(result.response.headers['content-type']).toBe 'application/xml; charset=utf-8'
                .then done, done.fail

        it 'should call done.fail if starting the server fails', (done) ->
            failSpy = jasmineHttpServerSpy.createSpyObj('mockServerOnSamePort', [
                {
                    method: 'get'
                    url: '/mockGet'
                    handlerName: 'getHandler'
                }
            ])

            mockDone = () -> done.fail('Expected call to mockDone.fail!')
            mockDone.fail = () -> done()

            failSpy.server.start(8082, mockDone)

    describe 'using promises', ->

        beforeEach (done) ->
            @httpSpy = jasmineHttpServerSpy.createSpyObj('mockServer', [
                {
                    method: 'get'
                    url: '/mockGet'
                    handlerName: 'getHandler'
                }
            ])

            @httpSpy.server.start(8082).then done, done.fail

        afterEach (done) ->
            @httpSpy.server.stop().then done, done.fail

        it 'should start and stop the server', (done) ->
            @httpSpy.getHandler.and.returnValue statusCode: 200

            makeRequest('http://localhost:8082/mockGet', method: 'GET')
                .then (result) ->
                    expect(result.response.statusCode).toBe 200
                .then done, done.fail

        it 'should reject the promise if starting the server fails', (done) ->
            failSpy = jasmineHttpServerSpy.createSpyObj('mockServerOnSamePort', [
                {
                    method: 'get'
                    url: '/mockGet'
                    handlerName: 'getHandler'
                }
            ])

            failSpy.server.start(8082).then done.fail, done

    describe 'http-server-spy with hostname', ->

        beforeEach (done) ->
            @httpSpy = jasmineHttpServerSpy.createSpyObj('mockServer', [
                {
                    method: 'get',
                    url: '/mockGet',
                    handlerName: 'getHandler'
                }
            ])

            @httpSpy.server.start(8082, '127.0.0.1').then done, done.fail

        afterEach (done) ->
            @httpSpy.server.stop().then done, done.fail

        it 'should start and stop the server', (done) ->
            @httpSpy.getHandler.and.returnValue statusCode: 200

            makeRequest('http://127.0.0.1:8082/mockGet', method: 'GET')
                .then (result) ->
                    expect(result.response.statusCode).toBe 200
                .then done, done.fail
