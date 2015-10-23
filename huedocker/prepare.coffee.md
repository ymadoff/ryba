# Cloudera Hue  build

Builds Hue from source 

    module.exports = []

    hue = {}
    hue.build ?= {}
    hue.build.name ?= 'ryba/hue-build'
    hue.build.dockerfile ?= "#{__dirname}/resources/build/Dockerfile"
    hue.build.directory ?= '/tmp/ryba/hue-build'
    machine = 'ryba'

    # Zeppelin compiling build from Dockerfile

Intermetiate container to build hue from source. Builds ryba/hue-build image


    module.exports.push name: 'Hue Build # Docker', timeout: -1, (options, next) ->
      fs.stat "#{hue.build.directory}/resources/hue-build.tar.gz", (err, stats) ->
        return ( if err.code == 'ENOENT' then do_build() else err ) if err
        fs.stat "#{hue.build.directory}/hue.tar", (err, stats) ->
            return do_end() unless  err 
            return if err.code == 'ENOENT' then do_image() else err        
      do_build = =>
        @
        .download
          source: hue.build.dockerfile
          destination: "#{hue.build.directory}/Dockerfile"
          force: true
        .docker_build
          image: hue.build.name
          cwd: hue.build.directory
          machine: machine
        .docker_stop
          machine: machine
          container: 'extractor'
          code_skipped: 1
        .docker_rm
          machine: machine
          container: 'extractor'
          code_skipped: 1
        .docker_run
          image: hue.build.name
          container: 'extractor'
          entrypoint: '/bin/bash'
          machine: machine
        .mkdir
          destination: "#{hue.build.directory}"
        .docker_cp
          source: '/hue-build.tar.gz'
          destination: "#{hue.build.directory}/resources/"
          machine: machine
          container: 'extractor'
        .docker_stop
          machine: machine
          container: 'extractor'
          code_skipped: 1
        .docker_rm
          machine: machine
          container: 'extractor'
          code_skipped: 1
        .then (err) ->
          return err if err
          fs.stat "#{hue.build.directory}/hue.tar", (err, stats) ->
            return do_end() unless  err 
            return if err.code == 'ENOENT' then do_image() else err
      do_image = =>
        @ 
        # .download
        #   source: "#{__dirname}/../../ryba-cluster-no-secure-4vm-2pc/resources/java/local_policy.jar"
        #   destination: "#{hue.build.directory}/resources/local_policy.jar"
        # .download
        #   source: "#{__dirname}/../../ryba-cluster-no-secure-4vm-2pc/resources/java/US_export_policy.jar"
        #   destination: "#{hue.build.directory}/resources/US_export_policy.jar"
        .download
          source: "#{__dirname}/resources/prod/Dockerfile"
          destination: "#{hue.build.directory}/Dockerfile"
          local: true
          force: true
        # .download
        #   source: "#{__dirname}/../../ryba-standalone-secure/conf/certs/cacert.pem"
        #   destination: "#{hue.build.directory}/resources/cacert.pem"
        # .download
        #   source: "#{__dirname}/../../ryba-standalone-secure/conf/certs/cacert_key.pem"
        #   destination: "#{hue.build.directory}/resources/cacert_key.pem"
        .download
          source: "#{__dirname}/resources/hue_init.sh"
          destination: "#{hue.build.directory}/resources/hue_init.sh"
          local: true
          force: true
        .docker_build
          image: 'ryba/hue:3.8'
          machine: machine
          cwd: hue.build.directory
        .then do_save
      do_save = =>
        @
        .docker_save
          image: 'ryba/hue:3.8'
          machine: machine
          destination: "#{hue.build.directory}/hue.tar"
        .then do_end
      do_end = =>
        console.log 'Hue Prepare Done'
        return      

## Dependencies  

    fs = require 'fs'

## Instructions
