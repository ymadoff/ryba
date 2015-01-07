
# Oozie Server

    module.exports = []

## Todo

*   [Configure JMS Provider JNDI connection mapping for HCatalog](http://oozie.apache.org/docs/4.0.0/AG_Install.html#HCatalog_Configuration)
*   [Notifications Configuration](http://oozie.apache.org/docs/4.0.0/AG_Install.html#Notifications_Configuration)
*   [Setting Up Oozie with HTTPS (SSL)](http://oozie.apache.org/docs/4.0.0/AG_Install.html#Setting_Up_Oozie_with_HTTPS_SSL)

## Configure

*   `oozie.user` (object|string)   
    The Unix Oozie login name or a user object (see Mecano User documentation).   
*   `oozie.group` (object|string)   
    The Unix Oozie group name or a group object (see Mecano Group documentation).   

Example

```json
    "oozie": {
      "user": {
        "name": "oozie", "system": true, "gid": "oozie",
        "comment": "Oozie User", "home": "/var/lib/oozie"
      },
      "group": {
        "name": "Oozie", "system": true
      }
    }
```

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('masson/commons/java').configure ctx
      require('../hadoop/core').configure ctx
      # require('./client').configure ctx
      {ryba} = ctx.config
      # Internal properties
      ryba.force_war ?= false
      # User
      ryba.oozie ?= {}
      ryba.oozie.user ?= {}
      ryba.oozie.user = name: ryba.oozie.user if typeof ryba.oozie.user is 'string'
      ryba.oozie.user.name ?= 'oozie'
      ryba.oozie.user.system ?= true
      ryba.oozie.user.gid ?= 'oozie'
      ryba.oozie.user.comment ?= 'Oozie User'
      ryba.oozie.user.home ?= '/var/lib/oozie'
      # Group
      ryba.oozie.group ?= {}
      ryba.oozie.group = name: ryba.oozie.group if typeof ryba.oozie.group is 'string'
      ryba.oozie.group.name ?= 'oozie'
      ryba.oozie.group.system ?= true
      # Layout
      ryba.oozie.conf_dir ?= '/etc/oozie/conf'
      ryba.oozie.data ?= '/var/db/oozie'
      ryba.oozie.log_dir ?= '/var/log/oozie'
      ryba.oozie.pid_dir ?= '/var/run/oozie'
      ryba.oozie.tmp_dir ?= '/var/tmp/oozie'
      # Configuration
      ryba.oozie.site ?= {}
      ryba.oozie.site['oozie.base.url'] = "http://#{ctx.config.host}:11000/oozie"
      # Configuration Database
      ryba.oozie.site['oozie.service.JPAService.jdbc.url'] ?= "jdbc:mysql://#{ryba.db_admin.host}:#{ryba.db_admin.port}/oozie?createDatabaseIfNotExist=true"
      ryba.oozie.site['oozie.service.JPAService.jdbc.driver'] ?= 'com.mysql.jdbc.Driver'
      ryba.oozie.site['oozie.service.JPAService.jdbc.username'] ?= 'oozie'
      ryba.oozie.site['oozie.service.JPAService.jdbc.password'] ?= 'oozie123'
      ryba.oozie.site['oozie.service.AuthorizationService.security.enabled'] ?= null # Now deprecated in favor of oozie.service.AuthorizationService.authorization.enabled (see oozie "oozie.log" file)
      ryba.oozie.site['oozie.service.AuthorizationService.authorization.enabled'] ?= 'true'
      ryba.oozie.site['oozie.service.HadoopAccessorService.kerberos.enabled'] ?= 'true'
      ryba.oozie.site['local.realm'] ?= "#{ryba.realm}"
      ryba.oozie.site['oozie.service.HadoopAccessorService.keytab.file'] ?= '/etc/oozie/conf/oozie.service.keytab'
      ryba.oozie.site['oozie.service.HadoopAccessorService.kerberos.principal'] ?= "oozie/#{ctx.config.host}@#{ryba.realm}"
      ryba.oozie.site['oozie.authentication.type'] ?= 'kerberos'
      ryba.oozie.site['oozie.authentication.kerberos.principal'] ?= "HTTP/#{ctx.config.host}@#{ryba.realm}"
      ryba.oozie.site['oozie.authentication.kerberos.keytab'] ?= '/etc/oozie/conf/spnego.service.keytab'
      # ryba.oozie.site['oozie.service.HadoopAccessorService.nameNode.whitelist'] = ''
      ryba.oozie.site['oozie.authentication.kerberos.name.rules'] ?= ryba.core_site['hadoop.security.auth_to_local']
      ryba.oozie.site['oozie.service.HadoopAccessorService.nameNode.whitelist'] ?= '' # Fix space value
      # ryba.extjs ?= {}
      # throw new Error "Missing extjs.source" unless ryba.extjs.source
      # throw new Error "Missing extjs.destination" unless ryba.extjs.destination
      # Note, we might also enrich "oozie.credentials.credentialclasses"
      # For example
      # ryba.oozie.site['oozie.credentials.credentialclasses'] = """
      # hcat=org.apache.oozie.action.hadoop.HCatCredentials,
      # hbase=org.apache.oozie.action.hadoop.HbaseCredentials
      # """

## Configuration for Proxy Users

      ryba.oozie.site['oozie.service.ProxyUserService.proxyuser.hive.hosts'] ?= "*"
      ryba.oozie.site['oozie.service.ProxyUserService.proxyuser.hive.groups'] ?= "*"
      ryba.oozie.site['oozie.service.ProxyUserService.proxyuser.hue.hosts'] ?= "*"
      ryba.oozie.site['oozie.service.ProxyUserService.proxyuser.hue.groups'] ?= "*"
      falcon_cts = ctx.contexts 'ryba/falcon', require('../falcon').configure
      if falcon_cts.length
        {user} = falcon_cts[0].config.ryba.falcon
        ryba.oozie.site["oozie.service.ProxyUserService.proxyuser.#{user.name}.hosts"] ?= "*"
        ryba.oozie.site["oozie.service.ProxyUserService.proxyuser.#{user.name}.groups"] ?= "*"
        ryba.oozie.site['oozie.service.ELService.ext.functions.coord-job-submit-instances'] = """
          now=org.apache.oozie.extensions.OozieELExtensions#ph1_now_echo,
          today=org.apache.oozie.extensions.OozieELExtensions#ph1_today_echo,
          yesterday=org.apache.oozie.extensions.OozieELExtensions#ph1_yesterday_echo,
          currentMonth=org.apache.oozie.extensions.OozieELExtensions#ph1_currentMonth_echo,
          lastMonth=org.apache.oozie.extensions.OozieELExtensions#ph1_lastMonth_echo, currentYear=org.apache.oozie.extensions.OozieELExtensions#ph1_currentYear_echo,
          lastYear=org.apache.oozie.extensions.OozieELExtensions#ph1_lastYear_echo,
          formatTime=org.apache.oozie.coord.CoordELFunctions#ph1_coord_formatTime_echo,
          latest=org.apache.oozie.coord.CoordELFunctions#ph2_coord_latest_echo,
          future=org.apache.oozie.coord.CoordELFunctions#ph2_coord_future_echo
          """
        ryba.oozie.site['oozie.service.ELService.ext.functions.coord-action-create-inst'] = """
          now=org.apache.oozie.extensions.OozieELExtensions#ph2_now_inst,
          today=org.apache.oozie.extensions.OozieELExtensions#ph2_today_inst,
          yesterday=org.apache.oozie.extensions.OozieELExtensions#ph2_yesterday_inst,
          currentMonth=org.apache.oozie.extensions.OozieELExtensions#ph2_currentMonth_inst,
          lastMonth=org.apache.oozie.extensions.OozieELExtensions#ph2_lastMonth_inst,
          currentYear=org.apache.oozie.extensions.OozieELExtensions#ph2_currentYear_inst,
          lastYear=org.apache.oozie.extensions.OozieELExtensions#ph2_lastYear_inst,
          latest=org.apache.oozie.coord.CoordELFunctions#ph2_coord_latest_echo,
          future=org.apache.oozie.coord.CoordELFunctions#ph2_coord_future_echo,
          formatTime=org.apache.oozie.coord.CoordELFunctions#ph2_coord_formatTime,
          user=org.apache.oozie.coord.CoordELFunctions#coord_user
          """
        ryba.oozie.site['oozie.service.ELService.ext.functions.coord-action-start'] = """
          now=org.apache.oozie.extensions.OozieELExtensions#ph2_now,
          today=org.apache.oozie.extensions.OozieELExtensions#ph2_today,
          yesterday=org.apache.oozie.extensions.OozieELExtensions#ph2_yesterday,
          currentMonth=org.apache.oozie.extensions.OozieELExtensions#ph2_currentMonth,
          lastMonth=org.apache.oozie.extensions.OozieELExtensions#ph2_lastMonth,
          currentYear=org.apache.oozie.extensions.OozieELExtensions#ph2_currentYear,
          lastYear=org.apache.oozie.extensions.OozieELExtensions#ph2_lastYear,
          latest=org.apache.oozie.coord.CoordELFunctions#ph3_coord_latest,
          future=org.apache.oozie.coord.CoordELFunctions#ph3_coord_future,
          dataIn=org.apache.oozie.extensions.OozieELExtensions#ph3_dataIn,
          instanceTime=org.apache.oozie.coord.CoordELFunctions#ph3_coord_nominalTime,
          dateOffset=org.apache.oozie.coord.CoordELFunctions#ph3_coord_dateOffset,
          formatTime=org.apache.oozie.coord.CoordELFunctions#ph3_coord_formatTime,
          user=org.apache.oozie.coord.CoordELFunctions#coord_user
          """
        ryba.oozie.site['oozie.service.ELService.ext.functions.coord-sla-submit'] = """
          instanceTime=org.apache.oozie.coord.CoordELFunctions#ph1_coord_nominalTime_echo_fixed,
          user=org.apache.oozie.coord.CoordELFunctions#coord_user
          """
        ryba.oozie.site['oozie.service.ELService.ext.functions.coord-sla-create'] = """
          instanceTime=org.apache.oozie.coord.CoordELFunctions#ph2_coord_nominalTime,
          user=org.apache.oozie.coord.CoordELFunctions#coord_user
          """

## Configuration for Hadoop

      ryba.oozie.hadoop_config ?= {}
      ryba.oozie.hadoop_config['mapreduce.jobtracker.kerberos.principal'] ?= "mapred/#{ryba.static_host}@#{ryba.realm}"
      ryba.oozie.hadoop_config['yarn.resourcemanager.principal'] ?= "yarn/#{ryba.static_host}@#{ryba.realm}"
      ryba.oozie.hadoop_config['dfs.namenode.kerberos.principal'] ?= "hdfs/#{ryba.static_host}@#{ryba.realm}"
      ryba.oozie.hadoop_config['mapreduce.framework.name'] ?= "yarn"

    # module.exports.push commands: 'backup', modules: 'ryba/oozie/server_backup'

    # module.exports.push commands: 'check', modules: 'ryba/oozie/server_check'

    module.exports.push commands: 'install', modules: 'ryba/oozie/server_install'

    module.exports.push commands: 'start', modules: 'ryba/oozie/server_start'

    module.exports.push commands: 'status', modules: 'ryba/oozie/server_status'

    module.exports.push commands: 'stop', modules: 'ryba/oozie/server_stop'


