
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
      hcat_ctxs = ctx.contexts 'ryba/hive/server', require('./server').configure
      uris = hcat_ctxs[0].config.ryba.hive.site['hive.metastore.uris'] 
      zookeeper_hosts = ctx.hosts_with_module 'ryba/zookeeper/server'
      for server of ctx.config.servers
        continue if (i = zookeeper_hosts.indexOf server.host) is -1
        zookeeper_hosts[i] = "#{zookeeper_hosts[i]}:#{ryba.zookeeper.port}"
      # ryba.webhcat.conf_dir ?= '/etc/hcatalog/conf/webhcat'
      ryba.webhcat ?= {}
      ryba.webhcat.conf_dir ?= '/etc/hive-webhcat/conf'
      ryba.webhcat.log_dir ?= '/var/log/webhcat'
      ryba.webhcat.pid_dir ?= '/var/run/webhcat'
      # WebHCat configuration
      ryba.webhcat.site ?= {}
      ryba.webhcat.site['templeton.storage.class'] ?= 'org.apache.hive.hcatalog.templeton.tool.ZooKeeperStorage' # Fix default value distributed in companion files
      ryba.webhcat.site['templeton.jar'] ?= '/usr/lib/hive-hcatalog/share/webhcat/svr/lib/hive-webhcat-0.13.0.2.1.2.0-402.jar' # Fix default value distributed in companion files
      ryba.webhcat.site['templeton.hive.properties'] ?= "hive.metastore.local=false,hive.metastore.uris=#{uris},hive.metastore.sasl.enabled=yes,hive.metastore.execute.setugi=true,hive.metastore.warehouse.dir=/apps/hive/warehouse"
      ryba.webhcat.site['templeton.zookeeper.hosts'] ?= zookeeper_hosts.join ','
      ryba.webhcat.site['templeton.kerberos.principal'] ?= "HTTP/#{ctx.config.host}@#{ryba.realm}"
      ryba.webhcat.site['templeton.kerberos.keytab'] ?= "#{ryba.webhcat.conf_dir}/spnego.service.keytab"
      ryba.webhcat.site['templeton.kerberos.secret'] ?= 'secret'
      ryba.webhcat.site['webhcat.proxyuser.hue.groups'] ?= '*'
      ryba.webhcat.site['webhcat.proxyuser.hue.hosts'] ?= '*'
      ryba.webhcat.site['templeton.port'] ?= 50111
      ryba.webhcat.site['templeton.controller.map.mem'] = 1600 # Total virtual memory available to map tasks.

    # module.exports.push commands: 'backup', modules: 'ryba/hive/webhcat_backup'

    module.exports.push commands: 'check', modules: 'ryba/hive/webhcat_check'

    module.exports.push commands: 'install', modules: 'ryba/hive/webhcat_install'

    module.exports.push commands: 'start', modules: 'ryba/hive/webhcat_start'

    module.exports.push commands: 'status', modules: 'ryba/hive/webhcat_status'

    module.exports.push commands: 'stop', modules: 'ryba/hive/webhcat_stop'




