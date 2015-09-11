
# Zookeeper Client

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('masson/commons/java').configure ctx
      require('masson/core/krb5_client').configure ctx
      {java_home} = ctx.config.java
      # User
      ctx.config.ryba.zookeeper ?= {}
      ctx.config.ryba.zookeeper.user ?= {}
      ctx.config.ryba.zookeeper.user = name: ctx.config.ryba.zookeeper.user if typeof ctx.config.ryba.zookeeper.user is 'string'
      ctx.config.ryba.zookeeper.user.name ?= 'zookeeper'
      ctx.config.ryba.zookeeper.user.system ?= true
      ctx.config.ryba.zookeeper.user.gid ?= 'zookeeper'
      ctx.config.ryba.zookeeper.user.groups ?= 'hadoop'
      ctx.config.ryba.zookeeper.user.comment ?= 'Zookeeper User'
      ctx.config.ryba.zookeeper.user.home ?= '/var/lib/zookeeper'
      # Groups
      ctx.config.ryba.zookeeper.group = name: ctx.config.ryba.zookeeper.group if typeof ctx.config.ryba.zookeeper.group is 'string'
      ctx.config.ryba.zookeeper.group ?= {}
      ctx.config.ryba.zookeeper.group.name ?= 'zookeeper'
      ctx.config.ryba.zookeeper.group.system ?= true
      # Hadoop Group is also defined in ryba/hadoop/core
      ctx.config.ryba.hadoop_group = name: ctx.config.ryba.hadoop_group if typeof ctx.config.ryba.hadoop_group is 'string'
      ctx.config.ryba.hadoop_group ?= {}
      ctx.config.ryba.hadoop_group.name ?= 'hadoop'
      ctx.config.ryba.hadoop_group.system ?= true
      # Layout
      ctx.config.ryba.zookeeper.conf_dir ?= '/etc/zookeeper/conf'
      ctx.config.ryba.zookeeper.log_dir ?= '/var/log/zookeeper'
      ctx.config.ryba.zookeeper.port ?= 2181
      # Environnment
      ctx.config.ryba.zookeeper.env ?= {}
      ctx.config.ryba.zookeeper.env['JAVA_HOME'] ?= "#{java_home}"
      ctx.config.ryba.zookeeper.env['CLIENT_JVMFLAGS'] ?= '-Djava.security.auth.login.config=/etc/zookeeper/conf/zookeeper-client.jaas'

## Commands

    module.exports.push commands: 'check', modules: 'ryba/zookeeper/client/check'

    module.exports.push commands: 'install', modules: [
      'ryba/zookeeper/client/install'
      'ryba/zookeeper/client/check'
    ]
