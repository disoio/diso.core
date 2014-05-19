module.exports = (grunt)->
  grunt.initConfig(
    pkg : grunt.file.readJSON('package.json')
    
    coffee: {
      glob_to_multiple: {
        expand: true,
        flatten: false,
        cwd: "#{__dirname}/source/",
        src: ['**/*.coffee'],
        dest: "#{__dirname}/"
        ext: '.js'
      },
    }
    
    watch: {
      files: 'source/**/*.coffee',
      tasks: ['coffee']
    }
  )
  
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-watch')
  
