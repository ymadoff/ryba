---
title: 
layout: module
---

# Zookeeper Server

Setting up a ZooKeeper server in standalone mode or in replicated mode.

A replicated group of servers in the same application is called a quorum, and in
replicated mode, all servers in the quorum have copies of the same configuration
file. The file is similar to the one used in standalone mode, but with a few
differences.

    module.exports = []

## Configure

*   `zookeeper_user` (object|string)   
    The Unix Zookeeper login name or a user object (see Mecano User documentation).   

Example : 

```json
{
  "ryba": {
    "zookeeper_user": {
      "name": "zookeeper", "system": true, "gid": "hadoop",
      "comment": "Zookeeper User", "home": "/var/lib/zookeeper"
    }
  }
}

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('masson/commons/java').configure ctx
      require('./client').configure ctx
      {java, ryba} = ctx.config
      # Environnment
      {zookeeper_conf_dir, zookeeper_log_dir, zookeeper_pid_dir, zookeeper_port} = ctx.config.ryba
      ryba.zookeeper_env ?= {}
      ryba.zookeeper_env['JAVA_HOME'] ?= "#{java.java_home}"
      ryba.zookeeper_env['ZOO_LOG_DIR'] ?= "#{zookeeper_log_dir}"
      ryba.zookeeper_env['ZOOPIDFILE'] ?= "#{zookeeper_pid_dir}/zookeeper_server.pid"
      ryba.zookeeper_env['SERVER_JVMFLAGS'] ?= "-Djava.security.auth.login.config=#{zookeeper_conf_dir}/zookeeper-server.jaas"
      ryba.zookeeper_env['CLIENT_JVMFLAGS'] ?= "-Djava.security.auth.login.config=#{zookeeper_conf_dir}/zookeeper-client.jaas"
      # Configuration
      hosts = ctx.hosts_with_module 'ryba/zookeeper/server'
      ryba.zookeeper_conf ?= {}
      # The number of milliseconds of each tick
      ryba.zookeeper_conf['tickTime'] ?= "2000"
      # The number of ticks that the initial
      # synchronization phase can take
      ryba.zookeeper_conf['initLimit'] ?= "10"
      ryba.zookeeper_conf['tickTime'] ?= "2000"
      # The number of ticks that can pass between
      # sending a request and getting an acknowledgement
      ryba.zookeeper_conf['syncLimit'] ?= "5"
      # the directory where the snapshot is stored.
      ryba.zookeeper_conf['dataDir'] ?= '/var/zookeper/data/'
      # the port at which the clients will connect
      ryba.zookeeper_conf['clientPort'] ?= "#{zookeeper_port}"
      if hosts.length > 1 then for host, i in hosts
        ryba.zookeeper_conf["server.#{i+1}"] = "#{host}:2888:3888"
      # SASL
      ryba.zookeeper_conf['authProvider.1'] ?= 'org.apache.zookeeper.server.auth.SASLAuthenticationProvider'
      ryba.zookeeper_conf['jaasLoginRenew'] ?= '3600000'
      ryba.zookeeper_conf['kerberos.removeHostFromPrincipal'] ?= 'true'
      ryba.zookeeper_conf['kerberos.removeRealmFromPrincipal'] ?= 'true'
      # Internal
      ryba.zookeeper_myid ?= null
      ryba.zookeeper_retention ?= '3' # Used to clean data dir

    # module.exports.push commands: 'backup', modules: 'ryba/zookeeper/server_backup'

    module.exports.push commands: 'check', modules: 'ryba/zookeeper/server_check'

    module.exports.push commands: 'install', modules: 'ryba/zookeeper/server_install'

    module.exports.push commands: 'start', modules: 'ryba/zookeeper/server_start'

    module.exports.push commands: 'status', modules: 'ryba/zookeeper/server_status'

    module.exports.push commands: 'stop', modules: 'ryba/zookeeper/server_stop'


