
# Zookeeper Client Configure

    module.exports = ->
      [zk_ctx] = @contexts 'ryba/zookeeper/server'
      {java} = @config
      zookeeper = @config.ryba.zookeeper ?= {}
      zookeeper.user ?= zk_ctx.config.user
      zookeeper.conf_dir ?= zk_ctx.config.ryba.zookeeper.conf_dir
      # Environnment
      zookeeper.env ?= {}
      zookeeper.env['JAVA_HOME'] ?= zk_ctx.config.ryba.zookeeper.env['JAVA_HOME']
      zookeeper.env['CLIENT_JVMFLAGS'] ?= '-Djava.security.auth.login.config=/etc/zookeeper/conf/zookeeper-client.jaas'
