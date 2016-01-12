
# Zookeeper Server

Setting up a ZooKeeper server in standalone mode or in replicated mode.

A replicated group of servers in the same application is called a quorum, and in
replicated mode, all servers in the quorum have copies of the same configuration
file. The file is similar to the one used in standalone mode, but with a few
differences.

    module.exports = []

## Configure

*   `zookeeper.user` (object|string)
    The Unix Zookeeper login name or a user object (see Mecano User documentation).

Example :

```json
{
  "ryba": {
    "zookeeper" : {
      "user": {
        "name": "zookeeper", "system": true, "gid": "hadoop",
        "comment": "Zookeeper User", "home": "/var/lib/zookeeper"
      }
    }
  }
}
```

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('masson/commons/java').configure ctx
      require('../client').configure ctx
      {java, ryba} = ctx.config
      zookeeper = ryba.zookeeper ?= {}
      # Layout
      zookeeper.pid_dir ?= '/var/run/zookeeper'
      # Auth to local
      zookeeper.auth_to_local ?= """
        RULE:[1:$1]
        RULE:[2:$1]
      """
      # Environnment
      zookeeper.env ?= {}
      zookeeper.env['JAVA_HOME'] ?= "#{java.java_home}"
      zookeeper.env['ZOOKEEPER_HOME'] ?= "/usr/hdp/current/zookeeper-client"
      zookeeper.env['ZOO_LOG_DIR'] ?= "#{zookeeper.log_dir}"
      zookeeper.env['ZOOPIDFILE'] ?= "#{zookeeper.pid_dir}/zookeeper_server.pid"
      zookeeper.env['SERVER_JVMFLAGS'] ?= "-Xmx1024m -Djava.security.auth.login.config=#{zookeeper.conf_dir}/zookeeper-server.jaas"
      zookeeper.env['CLIENT_JVMFLAGS'] ?= "-Djava.security.auth.login.config=#{zookeeper.conf_dir}/zookeeper-client.jaas"
      zookeeper.env['JAVA'] ?= '$JAVA_HOME/bin/java'
      zookeeper.env['CLASSPATH'] ?= '$CLASSPATH:/usr/share/zookeeper/*'
      zookeeper.env['ZOO_LOG4J_PROP'] = "INFO,CONSOLE,ROLLINGFILE"
      if zookeeper.env["JMXPORT"]? then zoookeeper.env['SERVER_JVMFLAGS'] = "#{zoookeeper.env['SERVER_JVMFLAGS']} -Dcom.sun.management.jmxremote.rmi.port=$JMXPORT"
      zookeeper.log4j ?= {}
      zookeeper.log4j[k] ?= v for k, v of ctx.config.log4j
      if zookeeper.log4j.server_port? then zookeeper.env['ZOO_LOG4J_PROP'] = "#{zookeeper.env['ZOO_LOG4J_PROP']},SOCKETHUB"
      if zookeeper.log4j.remote_host? && zookeeper.log4j.remote_port? then zookeeper.env['ZOO_LOG4J_PROP'] = "#{zookeeper.env['ZOO_LOG4J_PROP']},SOCKET"
      # Configuration
      hosts = ctx.hosts_with_module 'ryba/zookeeper/server'
      zookeeper.config ?= {}
      zookeeper.config['maxClientCnxns'] ?= '200'
      # The number of milliseconds of each tick
      zookeeper.config['tickTime'] ?= "2000"
      # The number of ticks that the initial synchronization phase can take
      zookeeper.config['initLimit'] ?= "10"
      zookeeper.config['tickTime'] ?= "2000"
      # The number of ticks that can pass between
      # sending a request and getting an acknowledgement
      zookeeper.config['syncLimit'] ?= "5"
      # the directory where the snapshot is stored.
      zookeeper.config['dataDir'] ?= '/var/zookeeper/data/'
      # the port at which the clients will connect
      zookeeper.config['clientPort'] ?= "#{zookeeper.port}"
      if hosts.length > 1 then for host, i in hosts
        zookeeper.config["server.#{i+1}"] = "#{host}:2888:3888"
      # SASL
      zookeeper.config['authProvider.1'] ?= 'org.apache.zookeeper.server.auth.SASLAuthenticationProvider'
      zookeeper.config['jaasLoginRenew'] ?= '3600000'
      zookeeper.config['kerberos.removeHostFromPrincipal'] ?= 'true'
      zookeeper.config['kerberos.removeRealmFromPrincipal'] ?= 'true'
      # Internal
      zookeeper.myid ?= null
      zookeeper.retention ?= 3 # Used to clean data dir
      zookeeper.purge ?= '@weekly'
      zookeeper.purge = '@weeekly' if zookeeper.purge is true
      # Superuser
      zookeeper.superuser ?= {}
      # zookeeper.superuser.password ?= 'ryba123'

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/zookeeper/server/backup'

    module.exports.push commands: 'check', modules: 'ryba/zookeeper/server/check'

    module.exports.push commands: 'install', modules: [
      'ryba/zookeeper/server/install'
      'ryba/zookeeper/server/start'
      'ryba/zookeeper/server/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/zookeeper/server/start'

    module.exports.push commands: 'status', modules: 'ryba/zookeeper/server/status'

    module.exports.push commands: 'stop', modules: 'ryba/zookeeper/server/stop'
