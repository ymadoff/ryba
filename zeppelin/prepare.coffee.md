# Apache Zeppelin build

Builds Zeppelin from as [required][zeppelin-build]. For now it's the single way to get Zeppelin.
It uses several containers. One to build zeppelin and an other for deploying zeppelin.
Requires Internet to download repository & maven.
Zeppelin 0.6 builds for Hadoop Cluster on Yarn with Spark.
Version:
  - Spark: 1.3
  - Hadoop: 2.7 (HDP 2.3)

    module.exports = []
    module.exports.push 'masson/bootstrap/log'

## Zeppelin compiling build from Dockerfile

Intermetiate container to build zeppelin from source. Builds ryba/zeppelin-build image

    module.exports.push header: 'Zeppelin Build # Docker', retry: 1, timeout: -1, handler: ->
      {zeppelin} = @config.ryba
      machine = 'ryba'
      @call
        handler: ->
          @docker_build
            machine: machine
            tag: zeppelin.build.name
            cwd: zeppelin.build.cwd
          @docker_run
            machine: machine
            image: zeppelin.build.name
            rm: true
            volume: "#{@config.mecano.cache_dir}:/target"
      # @call
      #   unless: (_, callback) ->
      #     fs.stat "#{zeppelin.build.directory}/zeppelin.tar", (err, stats) ->
      #       return callback null, !!err 
      #   handler: ->
      #     @download
      #       source: "#{__dirname}/../../ryba-cluster-no-secure-4vm-2pc/resources/java/local_policy.jar"
      #       destination: "#{zeppelin.build.directory}/resources/local_policy.jar"
      #     @download
      #       source: "#{__dirname}/../../ryba-cluster-no-secure-4vm-2pc/resources/java/US_export_policy.jar"
      #       destination: "#{zeppelin.build.directory}/resources/US_export_policy.jar"
      #     @download
      #       source: "#{__dirname}/../resources/zeppelin/prod/Dockerfile"
      #       destination: "#{zeppelin.build.directory}/Dockerfile"
      #       local: true
      #       force: true
      #     @docker_build
      #       image: 'ryba/zeppelin:0.6'
      #       machine: machine
      #       cwd: zeppelin.build.directory
      #     @docker_save
      #       image: 'ryba/zeppelin:0.6'
      #       machine: machine
      #       destination: "#{zeppelin.build.directory}/zeppelin.tar"   

## Dependencies  

    fs = require 'fs'

## Instructions

[zeppelin-build]:http://zeppelin.incubator.apache.org/docs/install/install.html
[github-instruction]:https://github.com/apache/incubator-zeppelin
[hortonwork-instruction]:http://fr.hortonworks.com/blog/introduction-to-data-science-with-apache-spark/
