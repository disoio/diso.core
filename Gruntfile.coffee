module.exports = (grunt)->
  grunt.initConfig(
    pkg : grunt.file.readJSON('package.json')
    
    coffee: {
      glob_to_multiple: {
        expand  : true
        flatten : false
        cwd     : "#{__dirname}/source/"
        src     : ['**/*.coffee']
        dest    : "#{__dirname}/"
        ext     : '.js'
      }
    }

    coffee_test: {
      glob_to_multiple: {
        expand  : true
        flatten : false
        cwd     : "#{__dirname}/test/"
        src     : ['**/*.coffee']
        dest    : "#{__dirname}/test/"
        ext     : '.js'
      }
    }
    
    watch: {
      files: '**/*.coffee',
      tasks: ['coffee', 'coffee_test']
    }
  )
  
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-watch')
  
