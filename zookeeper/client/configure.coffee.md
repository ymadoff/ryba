
# Zookeeper Client Configure

    module.exports = ->
      {java} = @config
      # User
      @config.ryba.zookeeper ?= {}
      @config.ryba.zookeeper.user ?= {}
      @config.ryba.zookeeper.user = name: @config.ryba.zookeeper.user if typeof @config.ryba.zookeeper.user is 'string'
      @config.ryba.zookeeper.user.name ?= 'zookeeper'
      @config.ryba.zookeeper.user.system ?= true
      @config.ryba.zookeeper.user.gid ?= 'zookeeper'
      @config.ryba.zookeeper.user.groups ?= 'hadoop'
      @config.ryba.zookeeper.user.comment ?= 'Zookeeper User'
      @config.ryba.zookeeper.user.home ?= '/var/lib/zookeeper'
      # Groups
      @config.ryba.zookeeper.group = name: @config.ryba.zookeeper.group if typeof @config.ryba.zookeeper.group is 'string'
      @config.ryba.zookeeper.group ?= {}
      @config.ryba.zookeeper.group.name ?= 'zookeeper'
      @config.ryba.zookeeper.group.system ?= true
      # Hadoop Group is also defined in ryba/hadoop/core
      @config.ryba.hadoop_group = name: @config.ryba.hadoop_group if typeof @config.ryba.hadoop_group is 'string'
      @config.ryba.hadoop_group ?= {}
      @config.ryba.hadoop_group.name ?= 'hadoop'
      @config.ryba.hadoop_group.system ?= true
      # Layout
      @config.ryba.zookeeper.conf_dir ?= '/etc/zookeeper/conf'
      @config.ryba.zookeeper.log_dir ?= '/var/log/zookeeper'
      @config.ryba.zookeeper.port ?= 2181
      # Environnment
      @config.ryba.zookeeper.env ?= {}
      @config.ryba.zookeeper.env['JAVA_HOME'] ?= "#{java.java_home}"
      @config.ryba.zookeeper.env['CLIENT_JVMFLAGS'] ?= '-Djava.security.auth.login.config=/etc/zookeeper/conf/zookeeper-client.jaas'
