module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    coffee: {
      compile: {
        options: {
          sourceMap: true
        },
        files: {
          'build/<%= pkg.name %>.js': ['src/*.coffee']
        }
      }
    },
    docco: {
      main: {
        src: ['src/**/*.coffee'],
        options: {
          output: 'docs/'
        }
      },
      test: {
        src: ['test/**/*.js'],
        options: {
          output: 'docs/'
        }
      }
    },
    regarde: {
      main: {
        files: 'src/**/*.coffee',
        tasks: ['default'],
        spawn: true
      },
      test: {
        files: 'test/**/*.js',
        tasks: ['test', 'docco:test'],
        spawn: true
      }
    },
    simplemocha: {
      options: {
        timeout: 3000,
        ignoreLeaks: false,
        ui: 'bdd',
        reporter: 'spec'
      },
      all: { src: 'test/**/*.js' }
    },
    uglify: {
      options: {
        banner: '/*! <%= pkg.name %> <%= pkg.version %> <%= grunt.template.today("yyyy-mm-dd")%> */\n',
        report: 'min',
        preserveComments: 'some'
      },
      build: {
        options: {
          sourceMapIn: 'build/<%= pkg.name %>.map',
          sourceMap: 'build/<%= pkg.name %>.min.map'
        },
        files: {
          'build/<%= pkg.name %>.min.js': 'build/<%= pkg.name %>.js'
        }
      }
    }
  });

  grunt.loadNpmTasks('grunt-docco');
  grunt.loadNpmTasks('grunt-regarde');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-simple-mocha');

  grunt.registerTask('default', ['test', 'coffee', 'uglify', 'docco']);
  grunt.registerTask('test', ['simplemocha']);
  grunt.registerTask('watch', ['regarde']);

};
