# jasmine-http-server-spy [![Build Status](https://travis-ci.org/..../......svg?branch=master)](https://travis-ci.org/..../....)

> Creates jasmine spy objects backed by a http server. Designed to help you write integration tests where your code 
makes real http requests to a server, where the server is controlled via the familiar jasmine spy api.
  
 
## Install

```
$ npm install --save jasmine-http-server-spy
```

## Usage

```coffee
# Integration jasmine spec
jasmineHttpServerSpy = require 'jasmine-http-server-spy'

describe 'Test', ->
    beforeAll (done) ->
        @httpSpy = jasmineHttpServerSpy.createSpyObj('mockServer', [
            {
                method: 'get'
                url: '/some-url-to-mock'
                handlerName: 'getSomeUrlToMock'
            }
        ])
        @httpSpy.server.start 8082, done
    
    afterAll (done) ->
        @httpSpy.server.stop done
       
    afterEach (done) ->
        @httpSpy.getSomeUrlToMock.calls.reset()
        
    it 'all the things', (done) ->
        # 1. Define what mock server would return
        @httpSpy.getSomeUrlToMock.and.returnValue 
            status: 200
            body: 
                data: 10
        # 2. ... calls to main service that uses 'http://localhost:8082/some-url-to-mock'
        # 3. Assert mock server has been called as expected
        expect(@httpSpy.getSomeUrlToMock).toHaveBeenCalled()
        # or
        expect(@httpSpy.getSomeUrlToMock).toHaveBeenCalledWith jasmine.objectContaining(
            body: 
                data: "something"
        )
```

## API

TBD
