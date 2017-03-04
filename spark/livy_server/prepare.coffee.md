
#  Livy Spark Server Prepare

Follows [Livy install][install-quickstart] guide wrap livy-server inside a docker container.
Id does not build Livy Spark Server from sources. An internet Connection is needed to be able to download.

N.B.: Can not build livy from source because livy rsc test server complain about network
when build inside container. Indeed docker builds images in isolated network, 
as a consequence even if a loopback address exists (container id), the tests 
throw an error.

Waiting for docker to deliver an net=host option for docker build command ! 

    module.exports = header: 'Spark Livy Prepare', timeout: -1,  handler: ->
      {spark} = @config.ryba

# Livy Spark Server Build dockerfile execution

      @call header: 'Prepare Build Container', timeout: -1,  handler: ->
        @system.mkdir
          target: "#{@config.nikita.cache_dir}/spark_livy_server"
        @system.mkdir
          target: "#{spark.livy.build.directory}/"
        @file.render
          source: spark.livy.build.dockerfile
          target: "#{spark.livy.build.directory}/Dockerfile"
          context: 
            source: "http://archive.cloudera.com/beta/livy/livy-server-#{spark.livy.build.version}.zip"
            version: spark.livy.build.version
            conf_dir: spark.livy.conf_dir
            home: spark.user.home
            user: spark.user.name
            group: spark.group.name
            uid: spark.user.uid
            gid: spark.user.uid
        @docker_build
          image: "#{spark.livy.build.name}:#{spark.livy.build.version}"
          file: "#{spark.livy.build.directory}/Dockerfile"
        @docker_save
          image: "#{spark.livy.build.name}:#{spark.livy.build.version}"
          output: "#{spark.livy.build.directory}/#{spark.livy.build.tar}"

## Instructions

[cloudera-livy]:(https://github.com/cloudera/livy)
[install-quickstart]:(http://livy.io/quickstart.html)
