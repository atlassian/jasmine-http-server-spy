import * as jasmineHttpSpyType from 'jasmine-http-server-spy';
import * as request from 'request';
let jasmineHttpSpy: typeof jasmineHttpSpyType = require('../../lib/jasmine-http-server-spy');

describe('TS type definition smoke test', () => {
    let httpSpy;

    beforeEach((done) => {
        httpSpy = jasmineHttpSpy.createSpyObj('mockServer', [
            {
                method: 'get',
                url: '/mockService/get',
                handlerName: 'getHandler'
            }
        ]);
        httpSpy.server.start(8082).then(done, done.fail);
    });

    afterEach((done) => {
        httpSpy.server.stop().then(done, done.fail);
    });

    it('should execute basic test using type script definition', (done) => {
        httpSpy.getHandler.and.returnValue({
            body: 'body',
            statusCode: 200
        })
        request('http://localhost:8082/mockService/get', {method: "GET"}, (error, response, body) => {
            expect(error).toBeNull();
            expect(response && response.statusCode).toBe(200);
            expect(body).toBe('body');
            done();
        })
    });
});
