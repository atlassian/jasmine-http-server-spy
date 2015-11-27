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
                src: ['lib/', 'build-output']
        shell:
            tsc:
                command: './node_modules/typescript/bin/tsc'
        jasmine:
            all:
                options:
                    jasmineConfig:
                        'spec_dir': 'test'
                        'spec_files': [ '**/*.spec.coffee' ]
            ts:
                options:
                    jasmineConfig:
                        'spec_dir': 'build-output'
                        'spec_files': ['test/*.spec.js']
        watch:
            options:
                atBegin: true
            test:
                files: ['src/**/*.coffee', 'test/**/*.coffee']
                tasks: ['default']

    require('load-grunt-tasks')(grunt)
    require('./grunt/jasmine-runner')(grunt)

    grunt.registerTask 'compile', ['clean', 'coffee']
    grunt.registerTask 'tsDefinitionTest', ['shell:tsc', 'jasmine:ts']
    grunt.registerTask 'default', ['compile', 'jasmine:all', 'tsDefinitionTest']
