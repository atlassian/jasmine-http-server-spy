module.exports = (grunt) ->

    grunt.initConfig
        coffee:
            compile:
                expand: true
                cwd: 'src/'
                src: '**/*.coffee'
                dest: 'lib/'
                ext: '.js'
        clean:
            compiled:
                src: 'lib/'
        jasmine:
            all:
                options:
                    jasmineConfig:
                        'spec_dir': 'test'
                        'spec_files': [ '**/*.spec.coffee' ]
        watch:
            options:
                atBegin: true
            test:
                files: ['src/**/*.coffee', 'test/**/*.coffee']
                tasks: ['default']

    require('load-grunt-tasks')(grunt)
    require('./grunt/jasmine-runner')(grunt)

    grunt.registerTask 'compile', ['clean', 'coffee']
    grunt.registerTask 'default', ['compile', 'jasmine']
