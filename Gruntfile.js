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
        src: ['src/*.coffee'],
        options: {
          output: 'docs/'
        }
      }
    },
    regarde: {
      js: {
        files: '**/*.coffee',
        tasks: ['default'],
        spawn: true
      }
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

  grunt.registerTask('default', ['coffee', 'uglify', 'docco']);
  grunt.registerTask('watch', ['regarde']);

};
