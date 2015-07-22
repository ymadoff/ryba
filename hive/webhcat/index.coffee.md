
# WebHCat
[WebHCat](https://cwiki.apache.org/confluence/display/Hive/WebHCat) is a REST API for HCatalog. (REST stands for "representational state transfer", a style of API based on HTTP verbs).  The original name of WebHCat was Templeton.

    module.exports = []

# Configure

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('../hcatalog').configure ctx
      require('../../hadoop/hdfs').configure ctx
      require('../../zookeeper/server').configure ctx
      {ryba} = ctx.config
      [hcat_ctx] = ctx.contexts 'ryba/hive/hcatalog', require('../hcatalog').configure
      throw Error "No Hive HCatalog Server Found" unless hcat_ctx
      webhcat = ctx.config.ryba.webhcat ?= {}
      webhcat.conf_dir ?= '/etc/hive-webhcat/conf'
      webhcat.log_dir ?= '/var/log/webhcat'
      webhcat.pid_dir ?= '/var/run/webhcat'
      # WebHCat configuration
      webhcat.site ?= {}
      webhcat.site['templeton.storage.class'] ?= 'org.apache.hive.hcatalog.templeton.tool.ZooKeeperStorage' # Fix default value distributed in companion files
      webhcat.site['templeton.jar'] ?= '/usr/lib/hive-hcatalog/share/webhcat/svr/lib/hive-webhcat-0.13.0.2.1.2.0-402.jar' # Fix default value distributed in companion files
      webhcat.site['templeton.hive.properties'] ?= [
        'hive.metastore.local=false'
        "hive.metastore.uris=#{hcat_ctx.config.ryba.hive.site['hive.metastore.uris'] }"
        'hive.metastore.sasl.enabled=yes'
        'hive.metastore.execute.setugi=true'
        'hive.metastore.warehouse.dir=/apps/hive/warehouse'
        "hive.metastore.kerberos.principal=HTTP/_HOST@#{hcat_ctx.config.ryba.hive.site['hive.metastore.kerberos.principal']}"
      ].join ','
      webhcat.site['templeton.zookeeper.hosts'] ?= hcat_ctx.config.ryba.hive.site['templeton.zookeeper.hosts']
      webhcat.site['templeton.kerberos.principal'] ?= "HTTP/#{ctx.config.host}@#{ryba.realm}" # "HTTP/#{ctx.config.host}@#{ryba.realm}"
      webhcat.site['templeton.kerberos.keytab'] ?= ryba.core_site['hadoop.http.authentication.kerberos.keytab']
      webhcat.site['templeton.kerberos.secret'] ?= 'secret'
      webhcat.site['webhcat.proxyuser.hue.groups'] ?= '*'
      webhcat.site['webhcat.proxyuser.hue.hosts'] ?= '*'
      webhcat.site['templeton.port'] ?= 50111
      webhcat.site['templeton.controller.map.mem'] = 1600 # Total virtual memory available to map tasks.

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/hive/webhcat/backup'

    module.exports.push commands: 'check', modules: 'ryba/hive/webhcat/check'

    module.exports.push commands: 'install', modules: [
      'ryba/hive/webhcat/install'
      'ryba/hive/webhcat/start'
      'ryba/hive/webhcat/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hive/webhcat/start'

    module.exports.push commands: 'status', modules: 'ryba/hive/webhcat/status'

    module.exports.push commands: 'stop', modules: 'ryba/hive/webhcat/stop'
