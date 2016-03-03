
# Configure webhcat server

    module.exports = handler: ->
      {ryba} = @config
      [hcat_ctx] = @contexts 'ryba/hive/hcatalog', require('../hcatalog/configure').handler
      throw Error "No Hive HCatalog Server Found" unless hcat_ctx
      webhcat = @config.ryba.webhcat ?= {}
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
      webhcat.site['templeton.kerberos.principal'] ?= "HTTP/#{@config.host}@#{ryba.realm}" # "HTTP/#{ctx.config.host}@#{ryba.realm}"
      webhcat.site['templeton.kerberos.keytab'] ?= ryba.core_site['hadoop.http.authentication.kerberos.keytab']
      webhcat.site['templeton.kerberos.secret'] ?= 'secret'
      webhcat.site['webhcat.proxyuser.hue.groups'] ?= '*'
      webhcat.site['webhcat.proxyuser.hue.hosts'] ?= '*'
      webhcat.site['webhcat.proxyuser.knox.groups'] ?= '*'
      webhcat.site['webhcat.proxyuser.knox.hosts'] ?= '*'
      webhcat.site['templeton.port'] ?= 50111
      webhcat.site['templeton.controller.map.mem'] = 1600 # Total virtual memory available to map tasks.
