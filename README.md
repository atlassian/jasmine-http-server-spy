# mock-server [![Build Status](https://travis-ci.org/..../......svg?branch=master)](https://travis-ci.org/..../....)

> Setup mock server with outside resources endpoints from Jasmine test and verify required mock server urls have been called
  
 
## Install

```
$ npm install --save-dev mock-server
```

## Usage

```coffee
# Integration jasmine spec
describe 'Test', ->
    beforeEach (done) ->
        routes = [
            {
                method: 'get'
                url: '/some-url-to-mock'
                handlerName: 'getSomeUrlToMock'
            }
        ]
        @mockServer = new MockServer(8082, routes)
        @handlers = @mockServer.getHandlers()
        @mockServer.start(done)
       
    afterEach (done) ->
        @mockServer.stop(done)
        
    it 'all the things', (done) ->
        # 1. Define what mock server would return
        @handlers.getSomeUrlToMock.and.returnValue 
            status: 200
            body: 
                data: 10
        # 2. ... calls to main service that uses 'http://localhost:8082/some-url-to-mock'
        # 3. Assert mock server has been called as expected
        expect(@handlers.getSomeUrlToMock).toHaveBeenCalled()
        # Since getSomeUrlToMock have been called with express 'request' you can assert specific details as well
```
