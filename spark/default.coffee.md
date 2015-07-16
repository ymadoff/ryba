# Spark default configuration install

Ths modules is not required directly in the list of configuration.
Its required by the other modules spark/client and spar/history_server

    

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_client'

    module.exports.push module.exports.configure = (ctx) ->
      require('../lib/base').configure ctx
      require('../hadoop/core').configure ctx
      {core_site} = ctx.config.ryba
      spark  = ctx.config.ryba.spark ?= {}
      spark.conf ?= {}
      spark.conf['spark.eventLog.dir'] ?= "#{core_site['fs.defaultFS']}/user/spark/applicationHistory"
      spark.conf['spark.history.fs.logDirectory'] ?= "#{spark.conf['spark.eventLog.dir']}"
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


## Spark Worker events log dir

    module.exports.push name: 'Spark Logdir # Permissions', handler: (ctx, next) ->
      {spark} = ctx.config.ryba
      fs_log_dir = spark.conf['spark.eventLog.Dir']
      ctx
      .execute
        cmd: mkcmd.hdfs ctx, """
          hdfs dfs -mkdir -p /user/#{spark.user.name}
          hdfs dfs -chown #{spark.user.name}:#{spark.group.name} /user/#{spark.user.name}
          hdfs dfs -mkdir -p #{fs_log_dir}
          hdfs dfs -chmod -R 755 /user/#{spark.user.name}
          hdfs dfs -chmod 1777 #{fs_log_dir}
          """
      .then next 

## Dependecies

    mkcmd = require '../lib/mkcmd'
    path = require 'path'
      