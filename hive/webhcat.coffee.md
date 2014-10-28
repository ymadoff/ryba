---
title: 
layout: module
---

# WebHCat

    module.exports = []

# Configure

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('./server').configure ctx
      require('../hadoop/hdfs').configure ctx
      require('../zookeeper/server').configure ctx
      require('../hive/server').configure ctx
      {ryba} = ctx.config
      hive_host = ctx.host_with_module 'ryba/hive/server'
      zookeeper_hosts = ctx.hosts_with_module 'ryba/zookeeper/server'
      for server of ctx.config.servers
        continue if (i = zookeeper_hosts.indexOf server.host) is -1
        zookeeper_hosts[i] = "#{zookeeper_hosts[i]}:#{ryba.zookeeper_port}"
      # ryba.webhcat_conf_dir ?= '/etc/hcatalog/conf/webhcat'
      ryba.webhcat_conf_dir ?= '/etc/hive-webhcat/conf'
      ryba.webhcat_log_dir ?= '/var/log/webhcat'
      ryba.webhcat_pid_dir ?= '/var/run/webhcat'
      # WebHCat configuration
      ryba.webhcat_site ?= {}
      ryba.webhcat_site['templeton.storage.class'] ?= 'org.apache.hive.hcatalog.templeton.tool.ZooKeeperStorage' # Fix default value distributed in companion files
      ryba.webhcat_site['templeton.jar'] ?= '/usr/lib/hive-hcatalog/share/webhcat/svr/lib/hive-webhcat-0.13.0.2.1.2.0-402.jar' # Fix default value distributed in companion files
      ryba.webhcat_site['templeton.hive.properties'] ?= "hive.metastore.local=false,hive.metastore.uris=thrift://#{hive_host}:9083,hive.metastore.sasl.enabled=yes,hive.metastore.execute.setugi=true,hive.metastore.warehouse.dir=/apps/hive/warehouse"
      ryba.webhcat_site['templeton.zookeeper.hosts'] ?= zookeeper_hosts.join ','
      ryba.webhcat_site['templeton.kerberos.principal'] ?= "HTTP/#{ctx.config.host}@#{ryba.realm}"
      ryba.webhcat_site['templeton.kerberos.keytab'] ?= "#{ryba.webhcat_conf_dir}/spnego.service.keytab"
      ryba.webhcat_site['templeton.kerberos.secret'] ?= 'secret'
      ryba.webhcat_site['webhcat.proxyuser.hue.groups'] ?= '*'
      ryba.webhcat_site['webhcat.proxyuser.hue.hosts'] ?= '*'
      ryba.webhcat_site['templeton.port'] ?= 50111
      ryba.webhcat_site['templeton.controller.map.mem'] = 1600 # Total virtual memory available to map tasks.

    # module.exports.push commands: 'backup', modules: 'ryba/hive/webhcat_backup'

    module.exports.push commands: 'check', modules: 'ryba/hive/webhcat_check'

    module.exports.push commands: 'install', modules: 'ryba/hive/webhcat_install'

    module.exports.push commands: 'start', modules: 'ryba/hive/webhcat_start'

    module.exports.push commands: 'status', modules: 'ryba/hive/webhcat_status'

    module.exports.push commands: 'stop', modules: 'ryba/hive/webhcat_stop'
