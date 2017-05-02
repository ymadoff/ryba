
# ZooKeeper Client Configure

*   `zookeeper.user` (object|string)   
    The Unix Zookeeper login name or a user object (see Nikita User documentation).   
*   `zookeeper.env` (object)   
    Map of variables present in "zookeeper-env.sh" and used to initialize the server.   
*   `zookeeper.config` (object)   
    Map of variables present in "zoo.cfg" and used to configure the server.   

Example :

```json
{ "ryba": {
    "zookeeper" : {
      "user": {
        "name": "zookeeper", "system": true, "gid": "hadoop",
        "comment": "Zookeeper User", "home": "/var/lib/zookeeper"
      }
    }
} }
```

    module.exports = ->
      zk_ctxs = @contexts 'ryba/zookeeper/server'
      {java} = @config
      @config.ryba ?= {}
      throw Error 'Missing configuration "ryba.realm"' unless @config.ryba?.realm
      zookeeper = @config.ryba.zookeeper ?= {}

## Environment

      # Layout
      zookeeper.conf_dir ?= '/etc/zookeeper/conf'
      zookeeper.log_dir ?= '/var/log/zookeeper'
      zookeeper.pid_dir ?= '/var/run/zookeeper'
      zookeeper.port ?= 2181
      zookeeper.conf_dir ?= '/etc/zookeeper/conf'

## Identities

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
      # User
      zookeeper.user ?= {}
      zookeeper.user = name: @config.ryba.zookeeper.user if typeof @config.ryba.zookeeper.user is 'string'
      zookeeper.user.name ?= 'zookeeper'
      zookeeper.user.system ?= true
      zookeeper.user.gid ?= zookeeper.group.name
      zookeeper.user.groups ?= 'hadoop'
      zookeeper.user.comment ?= 'Zookeeper User'
      zookeeper.user.home ?= '/var/lib/zookeeper'

## Configuration
      
      zookeeper.env ?= {}
      zookeeper.env['ZOOKEEPER_HOME'] ?= "/usr/hdp/current/zookeeper-client"
      zookeeper.env['ZOO_AUTH_TO_LOCAL'] ?= "RULE:[1:\\$1]RULE:[2:\\$1]"
      zookeeper.env['ZOO_LOG_DIR'] ?= "#{zookeeper.log_dir}"
      zookeeper.env['ZOOPIDFILE'] ?= "#{zookeeper.pid_dir}/zookeeper_server.pid"
      zookeeper.env['SERVER_JVMFLAGS'] ?= "-Xmx1024m -Djava.security.auth.login.config=#{zookeeper.conf_dir}/zookeeper-server.jaas"
      zookeeper.env['CLIENT_JVMFLAGS'] ?= "-Djava.security.auth.login.config=#{zookeeper.conf_dir}/zookeeper-client.jaas"
      zookeeper.env['JAVA'] ?= '$JAVA_HOME/bin/java'
      zookeeper.env['JAVA_HOME'] ?= "#{java.java_home}"
      zookeeper.env['CLASSPATH'] ?= '$CLASSPATH:/usr/share/zookeeper/*'
      zookeeper.env['ZOO_LOG4J_PROP'] ?= 'INFO,ROLLINGFILE' #was 'INFO,CONSOLE, ROLLINGFILE'
      if zookeeper.env['SERVER_JVMFLAGS'].indexOf('-Dzookeeper.security.auth_to_local') is -1
        zookeeper.env['SERVER_JVMFLAGS'] = "#{zookeeper.env['SERVER_JVMFLAGS']} -Dzookeeper.security.auth_to_local=$ZOO_AUTH_TO_LOCAL"
      if zookeeper.env['JMXPORT']? and zookeeper.env['SERVER_JVMFLAGS'].indexOf('-Dcom.sun.management.jmxremote.rmi.port') is -1
        zookeeper.env['SERVER_JVMFLAGS'] = "#{zookeeper.env['SERVER_JVMFLAGS']} -Dcom.sun.management.jmxremote.rmi.port=$JMXPORT"
      # Internal
      zookeeper.id ?= zk_ctxs.map((ctx) -> ctx.config.host).indexOf(@config.host)+1
      zookeeper.peer_port ?= 2888
      zookeeper.leader_port ?= 3888
      zookeeper.retention ?= 3 # Used to clean data dir
      zookeeper.purge ?= '@weekly'
      zookeeper.purge = '@weekly' if zookeeper.purge is true
      # Configuration
      zookeeper.config ?= {}
      zookeeper.config['maxClientCnxns'] ?= '200'
      # The number of milliseconds of each tick
      zookeeper.config['tickTime'] ?= '2000'
      # The number of ticks that the initial synchronization phase can take
      zookeeper.config['initLimit'] ?= '10'
      zookeeper.config['tickTime'] ?= '2000'
      # The number of ticks that can pass between
      # sending a request and getting an acknowledgement
      zookeeper.config['syncLimit'] ?= '5'
      # The directory where the snapshot is stored.
      # Recommandation is 1 dedicated SSD drive.
      zookeeper.config['dataDir'] ?= '/var/zookeeper/data/'
      # the port at which the clients will connect
      zookeeper.config['clientPort'] ?= "#{zookeeper.port}"
      # If zookeeper node is participant (to election) or only observer
      # Adding new observer nodes allow horizontal scaling without slowing write
      zookeeper.config['peerType'] ?= 'participant'
      connect_string = "#{@config.host}:#{zookeeper.peer_port}:#{zookeeper.leader_port}"
      connect_string += ":observer" if zookeeper.config['peerType'] is 'observer'
      for zk_ctx in zk_ctxs
        zk_ctx.config.ryba.zookeeper ?= {}
        zk_ctx.config.ryba.zookeeper.config ?= {}
        if zk_ctx.config.ryba.zookeeper.config["server.#{zookeeper.id}"]? and zk_ctx.config.ryba.zookeeper.config["server.#{zookeeper.id}"] isnt connect_string
          throw Error "Zk Server id '#{zookeeper.id}' is already registered on #{zk_ctx.config.host}"
        zk_ctx.config.ryba.zookeeper.config["server.#{zookeeper.id}"] = connect_string
      # SASL
      zookeeper.config['authProvider.1'] ?= 'org.apache.zookeeper.server.auth.SASLAuthenticationProvider'
      zookeeper.config['jaasLoginRenew'] ?= '3600000'
      zookeeper.config['kerberos.removeHostFromPrincipal'] ?= 'true'
      zookeeper.config['kerberos.removeRealmFromPrincipal'] ?= 'true'
      #http://zookeeper.apache.org/doc/trunk/zookeeperAdmin.html#sc_advancedConfiguration
      zookeeper.config['autopurge.snapRetainCount'] ?= '5'
      zookeeper.config['autopurge.purgeInterval'] ?= 4
      # Superuser
      zookeeper.superuser ?= {}
      # zookeeper.superuser.password ?= 'ryba123'
      # Log4J
      zookeeper.log4j ?= {}
      zookeeper.log4j[k] ?= v for k, v of @config.log4j
      if zookeeper.log4j.remote_host? and zookeeper.log4j.remote_port? and zookeeper.env['ZOO_LOG4J_PROP'].indexOf('SOCKET') is -1
        zookeeper.env['ZOO_LOG4J_PROP'] = "#{zookeeper.env['ZOO_LOG4J_PROP']},SOCKET"
      if zookeeper.log4j.server_port? and zookeeper.env['ZOO_LOG4J_PROP'].indexOf('SOCKETHUB') is -1
        zookeeper.env['ZOO_LOG4J_PROP'] = "#{zookeeper.env['ZOO_LOG4J_PROP']},SOCKETHUB"
      config = zookeeper.log4j.config ?= {}
      config['log4j.rootLogger'] ?= zookeeper.env['ZOO_LOG4J_PROP']
      config['log4j.appender.CONSOLE'] ?= 'org.apache.log4j.ConsoleAppender'
      config['log4j.appender.CONSOLE.Threshold'] ?= 'INFO'
      config['log4j.appender.CONSOLE.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.CONSOLE.layout.ConversionPattern'] ?= '%d{ISO8601} - %-5p [%t:%C{1}@%L] - %m%n'
      config['log4j.appender.ROLLINGFILE'] ?= 'org.apache.log4j.RollingFileAppender'
      config['log4j.appender.ROLLINGFILE.Threshold'] ?= 'DEBUG'
      config['log4j.appender.ROLLINGFILE.File'] ?= "#{zookeeper.log_dir}/zookeeper.log"
      config['log4j.appender.ROLLINGFILE.MaxFileSize'] ?= '10MB'
      config['log4j.appender.ROLLINGFILE.MaxBackupIndex'] ?= '10'
      config['log4j.appender.ROLLINGFILE.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.ROLLINGFILE.layout.ConversionPattern'] ?= '%d{ISO8601} - %-5p [%t:%C{1}@%L] - %m%n'
      config['log4j.appender.TRACEFILE'] ?= 'org.apache.log4j.FileAppender'
      config['log4j.appender.TRACEFILE.Threshold'] ?= 'TRACE'
      config['log4j.appender.TRACEFILE.File'] ?= "#{zookeeper.log_dir}/zookeeper_trace.log"
      config['log4j.appender.TRACEFILE.layout'] = 'org.apache.log4j.PatternLayout'
      config['log4j.appender.TRACEFILE.layout.ConversionPattern'] ?= '%d{ISO8601} - %-5p [%t:%C{1}@%L][%x] - %m%n'
      if zookeeper.log4j.server_port
        config['log4j.appender.SOCKETHUB'] ?= 'org.apache.log4j.net.SocketHubAppender'
        config['log4j.appender.SOCKETHUB.Application'] ?= 'zookeeper'
        config['log4j.appender.SOCKETHUB.Port'] ?= zookeeper.log4j.server_port
        config['log4j.appender.SOCKETHUB.BufferSize'] ?= '100'
      if zookeeper.log4j.remote_host and zookeeper.log4j.remote_port
        config['log4j.appender.SOCKET'] ?= 'org.apache.log4j.net.SocketAppender'
        config['log4j.appender.SOCKET.Application'] ?= 'zookeeper'
        config['log4j.appender.SOCKET.RemoteHost'] ?= zookeeper.log4j.remote_host
        config['log4j.appender.SOCKET.Port'] ?= zookeeper.log4j.remote_port
        config['log4j.appender.SOCKET.ReconnectionDelay'] ?= '10000'
