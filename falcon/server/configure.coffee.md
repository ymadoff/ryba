
# Falcon Server

[Apache Falcon](http://falcon.apache.org) is a data processing and management solution for Hadoop designed
for data motion, coordination of data pipelines, lifecycle management, and data
discovery. Falcon enables end consumers to quickly onboard their data and its
associated processing and management tasks on Hadoop clusters.


    module.exports = []

## Configure

    module.exports = handler: ->
      {realm} = @config.ryba
      falcon = @config.ryba.falcon ?= {}
      # Layout
      falcon.conf_dir ?= '/etc/falcon/conf'
      falcon.log_dir ?= '/var/log/falcon'
      falcon.pid_dir ?= '/var/run/falcon'
      falcon.server_opts ?= ''
      falcon.server_heap ?= ''
      # User
      falcon.user = name: falcon.user if typeof falcon.user is 'string'
      falcon.user ?= {}
      falcon.user.name ?= 'falcon'
      falcon.user.system ?= true
      falcon.user.comment ?= 'Falcon User'
      falcon.user.home ?= '/var/lib/falcon'
      falcon.user.groups ?= ['hadoop']
      # Group
      falcon.group = name: falcon.group if typeof falcon.group is 'string'
      falcon.group ?= {}
      falcon.group.name ?= 'falcon'
      falcon.group.system ?= true
      falcon.user.gid = falcon.group.name
      # Runtime
      falcon.runtime ?= {}
      falcon.runtime['prism.falcon.local.endpoint'] ?= "https://#{@config.host}:15443/"
      # Runtime (http://falcon.incubator.apache.org/Security.html)
      nn_contexts = @contexts 'ryba/hadoop/hdfs_nn', require('../../hadoop/hdfs_nn/configure').handler
      hcat_contexts = @contexts 'ryba/hive/hcatalog', [ require('../../commons/db_admin').handler, require('../../hive/hcatalog/configure').handler]
      # nn_rcp = nn_contexts[0].config.ryba.core_site['fs.defaultFS']
      # nn_protocol = if nn_contexts[0].config.ryba.hdfs.site['HTTP_ONLY'] then 'http' else 'https'
      # nn_nameservice = if nn_contexts[0].config.ryba.hdfs.site['dfs.nameservices'] then ".#{nn_contexts[0].config.ryba.hdfs.site['dfs.nameservices']}" else ''
      # nn_shortname = if nn_contexts.length then ".#{nn_contexts[0].config.shortname}" else ''
      # nn_http = ctx.config.ryba.hdfs.site["dfs.namenode.#{nn_protocol}-address#{nn_nameservice}#{nn_shortname}"]
      nn_principal = nn_contexts[0].config.ryba.hdfs.site['dfs.namenode.kerberos.principal']
      falcon.startup ?= {}
      falcon.startup['*.falcon.authentication.type'] ?= 'kerberos'
      falcon.startup['*.falcon.service.authentication.kerberos.principal'] ?= "#{falcon.user.name}/#{@config.host}@#{realm}"
      falcon.startup['*.falcon.service.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/falcon.service.keytab'
      falcon.startup['*.dfs.namenode.kerberos.principal'] ?= "#{nn_principal}"
      falcon.startup['*.falcon.http.authentication.type=kerberos'] ?= 'kerberos'
      falcon.startup['*.falcon.http.authentication.token.validity'] ?= '36000'
      falcon.startup['*.falcon.http.authentication.signature.secret'] ?= 'falcon' # Change this
      falcon.startup['*.falcon.http.authentication.cookie.domain'] ?= ''
      falcon.startup['*.falcon.http.authentication.kerberos.principal'] ?= "HTTP/#{@config.host}@#{realm}"
      falcon.startup['*.falcon.http.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab'
      falcon.startup['*.falcon.http.authentication.kerberos.name.rules'] ?= 'DEFAULT'
      falcon.startup['*.falcon.http.authentication.blacklisted.users'] ?= ''
      # Authorization Configuration
      # falcon.startup['*.falcon.security.authorization.enabled'] ?= 'true'
      # falcon.startup['*.falcon.security.authorization.provider'] ?= 'org.apache.falcon.security.DefaultAuthorizationProvider'
      # falcon.startup['*.falcon.security.authorization.superusergroup'] ?= 'falcon'
      # falcon.startup['*.falcon.security.authorization.admin.users'] ?= "#{falcon.user.name}"
      # falcon.startup['*.falcon.security.authorization.admin.groups'] ?= "#{falcon.group.name}"
      # falcon.startup['*.falcon.enableTLS'] ?= 'true'
      # falcon.startup['*.keystore.file'] ?= '/path/to/keystore/file'
      # falcon.startup['*.keystore.password'] ?= 'password'
      # falcon.startup[''] ?= ''
      # Cluster values in check
      # falcon.cluster['hadoop.rpc.protection'] ?= nn_contexts[0].config.ryba.core_site['hadoop.rpc.protection']
      # falcon.cluster['dfs.namenode.kerberos.principal'] ?= nn_contexts[0].config.ryba.hdfs.site['dfs.namenode.kerberos.principal']
      # falcon.cluster['hive.metastore.kerberos.principal'] ?= hcat_contexts[0].config.ryba.hive.site['hive.metastore.kerberos.principal']
      # falcon.cluster['hive.metastore.sasl.enabled'] ?= hcat_contexts[0].config.ryba.hive.site['hive.metastore.sasl.enabled']
      # falcon.cluster['hive.metastore.uris'] ?= hcat_contexts[0].config.ryba.hive.site['hive.metastore.uris']
      # Entity values in check
      # falcon.entity['dfs.namenode.kerberos.principal'] ?= nn_contexts[0].config.ryba.hdfs.site['dfs.namenode.kerberos.principal']
      # falcon.entity['hive.metastore.kerberos.principal'] ?= hcat_contexts[0].config.ryba.hive.site['hive.metastore.kerberos.principal']
      # falcon.entity['hive.metastore.sasl.enabled'] ?= hcat_contexts[0].config.ryba.hive.site['hive.metastore.sasl.enabled']
      # falcon.entity['hive.metastore.uris'] ?= hcat_contexts[0].config.ryba.hive.site['hive.metastore.uris']

## Configuration for Proxy Users

      falcon_hosts = @contexts('ryba/falcon/server').map((ctx) -> ctx.config.host).join ','
      hadoop_ctxs = @contexts ['ryba/hadoop/hdfs_nn','ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm']
      for hadoop_ctx in hadoop_ctxs
        hadoop_ctx.config.ryba ?= {}
        hadoop_ctx.config.ryba.core_site ?= {}
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{falcon.user.name}.groups"] ?= '*'
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{falcon.user.name}.hosts"] ?= falcon_hosts
      oozie_ctxs = @contexts 'ryba/oozie/server'
      for oozie_ctx in oozie_ctxs
        oozie_ctx.config.ryba ?= {}
        oozie = oozie_ctx.config.ryba.oozie ?= {}
        oozie.site ?= {}
        oozie.site["oozie.service.ProxyUserService.proxyuser.#{falcon.user.name}.hosts"] ?= falcon_hosts
        oozie.site["oozie.service.ProxyUserService.proxyuser.#{falcon.user.name}.groups"] ?= '*'
        oozie.site['oozie.service.URIHandlerService.uri.handlers'] ?= "org.apache.oozie.dependency.FSURIHandler,org.apache.oozie.dependency.HCatURIHandler"
        oozie.site['oozie.service.ELService.ext.functions.coord-job-submit-instances'] ?= """
          now=org.apache.oozie.extensions.OozieELExtensions#ph1_now_echo,
          today=org.apache.oozie.extensions.OozieELExtensions#ph1_today_echo,
          yesterday=org.apache.oozie.extensions.OozieELExtensions#ph1_yesterday_echo,
          currentMonth=org.apache.oozie.extensions.OozieELExtensions#ph1_currentMonth_echo,
          lastMonth=org.apache.oozie.extensions.OozieELExtensions#ph1_lastMonth_echo,
          currentYear=org.apache.oozie.extensions.OozieELExtensions#ph1_currentYear_echo,
          lastYear=org.apache.oozie.extensions.OozieELExtensions#ph1_lastYear_echo,
          formatTime=org.apache.oozie.coord.CoordELFunctions#ph1_coord_formatTime_echo,
          latest=org.apache.oozie.coord.CoordELFunctions#ph2_coord_latest_echo,
          future=org.apache.oozie.coord.CoordELFunctions#ph2_coord_future_echo
          """
        oozie.site['oozie.service.ELService.ext.functions.coord-action-create-inst'] ?= """
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
        oozie.site['oozie.service.ELService.ext.functions.coord-action-start'] ?= """
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
        oozie.site['oozie.service.ELService.ext.functions.coord-sla-submit'] = """
          instanceTime=org.apache.oozie.coord.CoordELFunctions#ph1_coord_nominalTime_echo_fixed,
          user=org.apache.oozie.coord.CoordELFunctions#coord_user
          """
        oozie.site['oozie.service.ELService.ext.functions.coord-sla-create'] = """
          instanceTime=org.apache.oozie.coord.CoordELFunctions#ph2_coord_nominalTime,
          user=org.apache.oozie.coord.CoordELFunctions#coord_user
          """
