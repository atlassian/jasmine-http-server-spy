Jasmine = require('jasmine')
jasmineReporters = require('jasmine-reporters')

reporters =
    junitXml: jasmineReporters.JUnitXmlReporter

addReporters = (jasmine, repotersConfig) ->
    repotersConfig = repotersConfig or {}
    for config, reporterName of repotersConfig
        reporterInstance = new (reporters[reporterName])(config)
        jasmine.addReporter reporterInstance

module.exports = (grunt) ->
    grunt.registerMultiTask 'jasmine', ->
        done = @async()
        options = @options()
        jasmine = new Jasmine
        jasmine.loadConfig options.jasmineConfig
        jasmine.configureDefaultReporter {}
        addReporters jasmine, options.reportersConfig
        jasmine.onComplete done
        jasmine.execute()
