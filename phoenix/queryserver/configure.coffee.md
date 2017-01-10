
# Phoenix QueryServer Configuration

    module.exports = ->
      {hbase, realm} = @config.ryba
      phoenix = @config.ryba.phoenix ?= {}

## Users and Groups

      phoenix.user ?= {}
      phoenix.user = name: phoenix.user if typeof phoenix.user is 'string'
      phoenix.user.name ?= 'phoenix'
      phoenix.user.system ?= true
      phoenix.user.comment ?= 'Phoenix User'
      phoenix.user.home ?= '/var/lib/phoenix'
      phoenix.user.groups ?= 'hadoop'
      # Group
      phoenix.group ?= {}
      phoenix.group = name: phoenix.group if typeof phoenix.group is 'string'
      phoenix.group.name ?= 'phoenix'
      phoenix.group.system ?= true
      phoenix.user.gid = phoenix.group.name

## Layout

      phoenix.conf_dir ?= '/etc/phoenix/conf'
      phoenix.log_dir ?= '/var/log/phoenix'
      phoenix.pid_dir ?= '/var/run/phoenix'

## QueryServer Configuration

      qs = phoenix.queryserver ?= {}
      qs.site ?= {}
      qs.site['phoenix.queryserver.http.port'] ?= '8765'
      qs.site['phoenix.queryserver.metafactory.class'] ?= 'org.apache.phoenix.queryserver.server.PhoenixMetaFactoryImpl'
      qs.site['phoenix.queryserver.serialization'] ?= 'PROTOBUF'
      qs.site['phoenix.queryserver.keytab.file'] ?= '/etc/security/keytabs/phoenix-queryserver.service.keytab'
      qs.site['phoenix.queryserver.kerberos.principal'] ?= "#{phoenix.user.name}/_HOST@#{realm}"
      qs.site['avatica.connectioncache.concurrency'] ?= '10'
      qs.site['avatica.connectioncache.initialcapacity'] ?= '100'
      qs.site['avatica.connectioncache.maxcapacity'] ?= '1000'
      qs.site['avatica.connectioncache.expiryduration'] ?= '10'
      qs.site['avatica.connectioncache.expiryunit'] ?= 'MINUTES'
      qs.site['avatica.statementcache.concurrency'] ?= '100'
      qs.site['avatica.statementcache.initialcapacity'] ?= '1000'
      qs.site['avatica.statementcache.maxcapacity'] ?= '10000'
      qs.site['avatica.statementcache.expiryduration'] ?= '5'
      qs.site['avatica.statementcache.expiryunit'] ?= 'MINUTES'
      qs.site[k] ?= v for k, v of hbase.site
