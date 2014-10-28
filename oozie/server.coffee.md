---
title: 
layout: module
---

# Oozie Server

    module.exports = []

## Configure

*   `oozie_user` (object|string)   
    The Unix Oozie login name or a user object (see Mecano User documentation).   
*   `oozie_group` (object|string)   
    The Unix Oozie group name or a group object (see Mecano Group documentation).   

Example

```json
    "oozie_user": {
      "name": "oozie", "system": true, "gid": "oozie",
      "comment": "Oozie User", "home": "/var/lib/oozie"
    }
    "oozie_group": {
      "name": "Oozie", "system": true
    }
```

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('masson/commons/java').configure ctx
      require('../hadoop/core').configure ctx
      require('./client').configure ctx
      {ryba} = ctx.config
      # Internal properties
      ryba.force_war ?= false
      # User
      ryba.oozie_user = name: ryba.oozie_user if typeof ryba.oozie_user is 'string'
      ryba.oozie_user ?= {}
      ryba.oozie_user.name ?= 'oozie'
      ryba.oozie_user.system ?= true
      ryba.oozie_user.gid ?= 'oozie'
      ryba.oozie_user.comment ?= 'Oozie User'
      ryba.oozie_user.home ?= '/var/lib/oozie'
      # Group
      ryba.oozie_group = name: ryba.oozie_group if typeof ryba.oozie_group is 'string'
      ryba.oozie_group ?= {}
      ryba.oozie_group.name ?= 'oozie'
      ryba.oozie_group.system ?= true
      # Layout
      ryba.oozie_conf_dir ?= '/etc/oozie/conf'
      ryba.oozie_data ?= '/var/db/oozie'
      ryba.oozie_log_dir ?= '/var/log/oozie'
      ryba.oozie_pid_dir ?= '/var/run/oozie'
      ryba.oozie_tmp_dir ?= '/var/tmp/oozie'
      # Configuration
      ryba.oozie_site ?= {}
      ryba.oozie_site['oozie.base.url'] = "http://#{ctx.config.host}:11000/oozie"
      # Configuration Database
      ryba.oozie_site['oozie.service.JPAService.jdbc.url'] ?= "jdbc:mysql://#{ryba.db_admin.host}:#{ryba.db_admin.port}/oozie?createDatabaseIfNotExist=true"
      ryba.oozie_site['oozie.service.JPAService.jdbc.driver'] ?= 'com.mysql.jdbc.Driver'
      ryba.oozie_site['oozie.service.JPAService.jdbc.username'] ?= 'oozie'
      ryba.oozie_site['oozie.service.JPAService.jdbc.password'] ?= 'oozie123'
      ryba.oozie_site['oozie.service.AuthorizationService.security.enabled'] ?= 'true' # Todo, now deprecated should be set to null in favor of oozie.service.AuthorizationService.authorization.enabled (see oozie "oozie.log" file)
      ryba.oozie_site['oozie.service.HadoopAccessorService.kerberos.enabled'] ?= 'true'
      ryba.oozie_site['local.realm'] ?= "#{ryba.realm}"
      ryba.oozie_site['oozie.service.HadoopAccessorService.keytab.file'] ?= '/etc/oozie/conf/oozie.service.keytab'
      ryba.oozie_site['oozie.service.HadoopAccessorService.kerberos.principal'] ?= "oozie/#{ctx.config.host}@#{ryba.realm}"
      ryba.oozie_site['oozie.authentication.type'] ?= 'kerberos'
      ryba.oozie_site['oozie.authentication.kerberos.principal'] ?= "HTTP/#{ctx.config.host}@#{ryba.realm}"
      ryba.oozie_site['oozie.authentication.kerberos.keytab'] ?= '/etc/oozie/conf/spnego.service.keytab'
      # ryba.oozie_site['oozie.service.HadoopAccessorService.nameNode.whitelist'] = ''
      ryba.oozie_site['oozie.authentication.kerberos.name.rules'] ?= ryba.core_site['hadoop.security.auth_to_local']
      ryba.oozie_site['oozie.service.HadoopAccessorService.nameNode.whitelist'] ?= '' # Fix space value
      ryba.oozie_site['oozie.service.ProxyUserService.proxyuser.hive.hosts'] ?= "*"
      ryba.oozie_site['oozie.service.ProxyUserService.proxyuser.hive.groups'] ?= "*"
      ryba.oozie_site['oozie.service.ProxyUserService.proxyuser.hue.hosts'] ?= "*"
      ryba.oozie_site['oozie.service.ProxyUserService.proxyuser.hue.groups'] ?= "*"
      ryba.oozie_hadoop_config ?= {}
      ryba.oozie_hadoop_config['mapreduce.jobtracker.kerberos.principal'] ?= "mapred/#{ryba.static_host}@#{ryba.realm}"
      ryba.oozie_hadoop_config['yarn.resourcemanager.principal'] ?= "yarn/#{ryba.static_host}@#{ryba.realm}"
      ryba.oozie_hadoop_config['dfs.namenode.kerberos.principal'] ?= "hdfs/#{ryba.static_host}@#{ryba.realm}"
      ryba.oozie_hadoop_config['mapreduce.framework.name'] ?= "yarn"
      ryba.extjs ?= {}
      throw new Error "Missing extjs.source" unless ryba.extjs.source
      throw new Error "Missing extjs.destination" unless ryba.extjs.destination

    # module.exports.push commands: 'backup', modules: 'ryba/oozie/server_backup'

    # module.exports.push commands: 'check', modules: 'ryba/oozie/server_check'

    module.exports.push commands: 'install', modules: 'ryba/oozie/server_install'

    module.exports.push commands: 'start', modules: 'ryba/oozie/server_start'

    # module.exports.push commands: 'status', modules: 'ryba/oozie/server_status'

    module.exports.push commands: 'stop', modules: 'ryba/oozie/server_stop'


