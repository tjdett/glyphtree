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
    uglify: {
      options: {
        banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n',
        report: 'min'
      },
      build: {
        options: {
          sourceMapIn: "build/<%= pkg.name %>.map",
          sourceMap: "build/<%= pkg.name %>.min.map"
        },
        files: {
          'build/<%= pkg.name %>.min.js': 'build/<%= pkg.name %>.js'
        }
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-uglify');

  grunt.registerTask('default', ['coffee', 'uglify']);

};
