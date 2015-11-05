# Apache Zeppelin build

Builds Zeppelin from as [required][zeppelin-build]. For now it's the single way to get Zeppelin.
It uses several containers. One to build zeppelin and an other for deploying zeppelin.
Requires Internet to download repository & maven.
Zeppelin 0.6 builds for Hadoop Cluster on Yarn with Spark.
Version:
  - Spark: 1.3
  - Hadoop: 2.7 (HDP 2.3)


    module.exports = []
    #module.exports.push () ->
    zeppelin = {}
    zeppelin.destination = '/var/lib/zeppelin'
    zeppelin.conf_dir = '/var/lib/zeppelin/conf'
    #Set to true if you want to deploy from build 
    #in this case zeppelin.source is required
    zeppelin.build ?= {}
    zeppelin.build.name ?= 'ryba/zeppelin-build'
    zeppelin.build.dockerfile ?= "#{__dirname}/../resources/zeppelin/build/Dockerfile"
    zeppelin.build.directory ?= '/tmp/ryba/zeppelin-build'
    machine = 'ryba'

## Zeppelin compiling build from Dockerfile

Intermetiate container to build zeppelin from source. Builds ryba/zeppelin-build image


    module.exports.push header: 'Zeppelin Build # Docker', timeout: -1, (options, next) ->
      fs.stat "#{zeppelin.build.directory}/resources/zeppelin-build.tar.gz", (err, stats) ->
        return do_image() unless  err 
        return if err.code == 'ENOENT' then do_build() else err
      do_build = =>
        @
        .download
          source: zeppelin.build.dockerfile
          destination: "#{zeppelin.build.directory}/Dockerfile"
          force: true
        .docker_build
          image: zeppelin.build.name
          cwd: zeppelin.build.directory
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
          image: zeppelin.build.name
          container: 'extractor'
          entrypoint: '/bin/bash'
          machine: machine
        .mkdir
          destination: "#{zeppelin.build.directory}"
        .docker_cp
          source: '/zeppelin-build.tar.gz'
          destination: "#{zeppelin.build.directory}/resources/"
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
          fs.stat "#{zeppelin.build.directory}/zeppelin.tar", (err, stats) ->
            return do_end() unless  err 
            return if err.code == 'ENOENT' then do_image() else err 
      do_image = =>
        @
        .download
          source: "#{__dirname}/../../ryba-cluster-no-secure-4vm-2pc/resources/java/local_policy.jar"
          destination: "#{zeppelin.build.directory}/resources/local_policy.jar"
        .download
          source: "#{__dirname}/../../ryba-cluster-no-secure-4vm-2pc/resources/java/US_export_policy.jar"
          destination: "#{zeppelin.build.directory}/resources/US_export_policy.jar"
        .download
          source: "#{__dirname}/../resources/zeppelin/prod/Dockerfile"
          destination: "#{zeppelin.build.directory}/Dockerfile"
          local: true
          force: true
        .docker_build
          image: 'ryba/zeppelin:0.6'
          machine: machine
          cwd: zeppelin.build.directory
        .then do_save
      do_save = =>
        @
        .docker_save
          image: 'ryba/zeppelin:0.6'
          machine: machine
          destination: "#{zeppelin.build.directory}/zeppelin.tar"
        .then do_end
      do_end = =>
        return      

## Dependencies  

    fs = require 'fs'

## Instructions

[zeppelin-build]:http://zeppelin.incubator.apache.org/docs/install/install.html
[github-instruction]:https://github.com/apache/incubator-zeppelin
[hortonwork-instruction]:http://fr.hortonworks.com/blog/introduction-to-data-science-with-apache-spark/
