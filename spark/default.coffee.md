# Spark default configuration install

Ths modules is not required directly in the list of configuration.
Its required by the other modules spark/client and spar/history_server



    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_client'

    module.exports.configure = (ctx) ->
      require('../lib/base').configure ctx
      require('../hadoop/core').configure ctx
      {core_site} = ctx.config.ryba
      spark  = ctx.config.ryba.spark ?= {}
      spark.conf ?= {}
      # Group
      spark.group ?= {}
      spark.group = name: spark.group if typeof spark.group is 'string'
      spark.group.name ?= 'spark'
      spark.group.system ?= true
      # User
      spark.user ?= {}
      spark.user = name: spark.user if typeof spark.user is 'string'
      spark.user.name ?= 'spark'
      spark.user.system ?= true
      spark.user.comment ?= 'Spark User'
      spark.user.home ?= '/var/run/spark'
      spark.user.groups ?= 'hadoop'
      spark.user.gid ?= spark.group.name
      # Base directory in which Spark events are logged, if spark.eventLog.enabled is true.
      # Within this base directory, Spark creates a sub-directory for each application, and logs the events specific to the application in this directory.
      # Users may want to set this to a unified location like an HDFS directory so history files can be read by the history server.
      spark.conf['spark.eventLog.dir'] ?= "#{core_site['fs.defaultFS']}/user/#{spark.user.name}/applicationHistory"
      spark.conf['spark.history.fs.logDirectory'] ?= "#{spark.conf['spark.eventLog.dir']}"
      spark.conf['spark.yarn.jar'] ?= "hdfs:///apps/#{spark.user.name}/spark-assembly.jar"


## Spark Worker events log dir

    module.exports.push header: 'Spark # Logdir HDFS Permissions', handler: ->
      {spark} = @config.ryba
      fs_log_dir = spark.conf['spark.eventLog.dir']
      @execute
        cmd: mkcmd.hdfs @, """
          hdfs dfs -mkdir -p /user/#{spark.user.name}
          hdfs dfs -mkdir -p #{fs_log_dir}
          hdfs dfs -chown -R #{spark.user.name}:#{spark.group.name} /user/#{spark.user.name}
          hdfs dfs -chmod -R 755 /user/#{spark.user.name}
          hdfs dfs -chmod 1777 #{fs_log_dir}
          """

## HFDS Layout

    module.exports.push header: 'Spark # HFDS Layout', handler: ->
      {spark} = @config.ryba
      status = user_owner = group_owner = null
      spark_yarn_jar = spark.conf['spark.yarn.jar']
      @execute
        cmd: mkcmd.hdfs @, """
          hdfs dfs -mkdir -p /apps/#{spark.user.name}
          hdfs dfs -chown -R #{spark.user.name}:#{spark.group.name} /apps/#{spark.user.name}
          hdfs dfs -chmod 755 /apps/#{spark.user.name}
          hdfs dfs -put -f /usr/hdp/current/spark-client/lib/spark-assembly-*.jar #{spark_yarn_jar}
          hdfs dfs -chown #{spark.user.name}:#{spark.group.name} #{spark_yarn_jar}
          hdfs dfs -chmod 644 #{spark_yarn_jar}
          """
  
## Dependecies

    mkcmd = require '../lib/mkcmd'
    path = require 'path'
