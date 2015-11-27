declare module JasmineHttpSpy {
    interface Route {
        method: string,
        url: string,
        handlerName: string
    }

    interface JasmineHttpSpyStatic {
        createSpyObj(name: string, routes: Array<Route>);
    }
}

declare var jasmineHttpSpy: JasmineHttpSpy.JasmineHttpSpyStatic;

declare module "jasmine-http-server-spy" {
    export = jasmineHttpSpy;
}
