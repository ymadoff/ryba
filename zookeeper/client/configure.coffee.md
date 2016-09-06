
# Zookeeper Client Configure

    module.exports = handler: ->
      {java} = @config
      # User
      zookeeper = @config.ryba.zookeeper ?= {}
      zookeeper.user ?= {}
      zookeeper.user = name: @config.ryba.zookeeper.user if typeof @config.ryba.zookeeper.user is 'string'
      zookeeper.user.name ?= 'zookeeper'
      zookeeper.user.system ?= true
      zookeeper.user.gid ?= 'zookeeper'
      zookeeper.user.groups ?= 'hadoop'
      zookeeper.user.comment ?= 'Zookeeper User'
      zookeeper.user.home ?= '/var/lib/zookeeper'
      # Groups
      zookeeper.group = name: @config.ryba.zookeeper.group if typeof @config.ryba.zookeeper.group is 'string'
      zookeeper.group ?= {}
      zookeeper.group.name ?= 'zookeeper'
      zookeeper.group.system ?= true
      # Hadoop Group is also defined in ryba/hadoop/core
      @config.ryba.hadoop_group = name: @config.ryba.hadoop_group if typeof @config.ryba.hadoop_group is 'string'
      @config.ryba.hadoop_group ?= {}
      @config.ryba.hadoop_group.name ?= 'hadoop'
      @config.ryba.hadoop_group.system ?= true
      # Layout
      zookeeper.conf_dir ?= '/etc/zookeeper/conf'
      zookeeper.log_dir ?= '/var/log/zookeeper'
      # Environnment
      zookeeper.env ?= {}
      zookeeper.env['JAVA_HOME'] ?= "#{java.java_home}"
      zookeeper.env['CLIENT_JVMFLAGS'] ?= '-Djava.security.auth.login.config=/etc/zookeeper/conf/zookeeper-client.jaas'
