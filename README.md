# jasmine-http-server-spy

> Creates jasmine spy objects backed by a http server. Designed to help you write integration tests where your code 
makes real http requests to a server, where the server is controlled via the familiar jasmine spy api.
  
 
## Install

```
$ npm install --save jasmine-http-server-spy
```

## API

### Server API by example

```javascript
var jasmineHttpServerSpy = require('jasmine-http-server-spy');

describe('Test', function() {
  beforeAll(function(done) {
    this.httpSpy = jasmineHttpServerSpy.createSpyObj('mockServer', [
      {
        method: 'get',
        url: '/some-url-to-mock',
        handlerName: 'getSomeUrlToMock'
      }
    ]);
    this.httpSpy.server.start(8082, done);
    // you can pass jasmine 'done' function as a callback, or use returned promise
    // this.httpSpy.server.start(8082).then(done, done.fail);
    // you can also specify the hostname to start the server on:
    // this.httpSpy.server.start(8082, '127.0.0.1').then(done, done.fail);
    // this is useful if you need to test multiple servers listening on the same port
  });
  
  afterAll(function(done) {
    this.httpSpy.server.stop(done)
    // you can pass jasmine 'done' function as a callback, or use returned promise:
    // this.httpSpy.server.stop().then(done, done.fail);
  });
  
  afterEach(function() {
    this.httpSpy.getSomeUrlToMock.calls.reset();
  });
  
  it('all the things', function() {
    // 1. Define what mock server would return
    this.httpSpy.getSomeUrlToMock.and.returnValue({
      statusCode: 200,
      body: {
        data: 10
      }
    });
    
    // 2. ... calls to main service that uses 'http://localhost:8082/some-url-to-mock'
    
    // 3. Assert mock server has been called as expected
    expect(this.httpSpy.getSomeUrlToMock).toHaveBeenCalled();
    
    // or
    expect(this.httpSpy.getSomeUrlToMock).toHaveBeenCalledWith(jasmine.objectContaining({
      body: {
        data: "something"
      }
    }));
  });
  
  it('can accept promise as handler returnValue', function() {
    var deferred = q.defer(); 
    this.httpSpy.getSomeUrlToMock.and.returnValue(deferred.promise);
    setTimeout(function(){
        deferred.resolve({
          statusCode: 200,
           body: {
             data: 10
           }
        });
    });
  });
});
```

### Handler's expected output

Handler function result will end up in the http response mock server gives back. 
You can define ```code```, ```body``` and ```headers``` at the moment:
 
```coffee
httpSpy.getSomeUrlToMock.and.returnValue {code: 200, body: {data: []}}

httpSpy.getSomeUrlToMock.and.returnValue {code: 200, body: '<xml>...</xml>', headers: {'Content-Type' : 'application/xml'}}

httpSpy.getSomeUrlToMock.and.returnValue {code: 401, body: {message: 'Please login first'}}
```

### Handler's input

While handlers are jasmine spy objects, you can define a callback function to make response dynamic. For example:

```coffee
httpSpy.getAnswerForANumber.and.callFake (req) ->
    code: 200
    body:
        if req.body.number is 42
            {answer: 'The answer to the ultimate question of life, the universe and everything'}
        else
            {answer: "I don't know"}
```

You can expect following properties in the first argument of this callback:
 
#### body

JS Object representing JSON body of a request. This object defaults to ```{}```.
 
#### query

Object containing all query parameters used. This object defaults to ```{}```.

#### originalUrl

Requested original URL. For example request to ```http://localhost:8082/mockService/users?something``` end up as 
```/mockService/users?something``` in ```originalUrl```

#### headers

Object containing all headers provided with request.

#### params

An object containing properties mapped to the named route "parameters". 
For example, if you have the route ```/user/:name```, then the "name" property is available as ```req.params.name```. 
This object defaults to ```{}```.

## Changelog

### 0.3.1
   
`start` now accepts hostname as optional second parameter `start(8082, '127.0.0.1')`

### 0.3.0

`start` and `stop` function return promise now. Use of jasmine `done` callback is now optional.

## Contribute

Feel free to fork it here https://bitbucket.org/atlassian/jasmine-http-server-spy/fork and make a pull request. 
 Issues and suggestions can be added here https://bitbucket.org/atlassian/jasmine-http-server-spy/issues
