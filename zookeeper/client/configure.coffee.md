
# Zookeeper Client Configure

    module.exports = ->
      [zoo_server] = @contexts 'ryba/zookeeper/server'
      {java} = @config
      zookeeper = @config.ryba.zookeeper ?= {}
      zookeeper.user ?= zoo_server.config.user
      zookeeper.conf_dir ?= zoo_server.config.ryba.zookeeper.conf_dir
      # Environnment
      zookeeper.env ?= {}
      zookeeper.env['JAVA_HOME'] ?= zoo_server.config.ryba.zookeeper.env['JAVA_HOME']
      zookeeper.env['CLIENT_JVMFLAGS'] ?= '-Djava.security.auth.login.config=/etc/zookeeper/conf/zookeeper-client.jaas'
