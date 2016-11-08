

# YARN Client Configure

    module.exports = ->
      {java} = @config
      [ats_ctx] = @contexts 'ryba/hadoop/yarn_ts'
      yc_ctxs = @contexts 'ryba/hadoop/yarn_client'
      nm_ctxs = @contexts 'ryba/hadoop/yarn_nm'
      rm_ctxs = @contexts 'ryba/hadoop/yarn_rm'
      {ryba} = @config
      {realm} = ryba
      # Grab the host(s) for each roles
      ryba.yarn.libexec ?= '/usr/hdp/current/hadoop-client/libexec'
      ryba.yarn.log_dir ?= '/var/log/hadoop-yarn'
      ryba.yarn.pid_dir ?= '/var/run/hadoop-yarn'
      ryba.yarn.conf_dir ?= ryba.hadoop_conf_dir
      ryba.yarn.opts ?= ''
      ryba.yarn.heapsize ?= '1024'
      ryba.yarn.home ?= '/usr/hdp/current/hadoop-yarn-client'
      ryba.yarn.site['yarn.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      # Configure yarn
      # Fix yarn application classpath, some application like the distributed shell
      # wont replace "hdp.version" and result in class not found.
      # ryba.yarn.site['yarn.application.classpath'] ?= "$HADOOP_CONF_DIR,/usr/hdp/${hdp.version}/hadoop-client/*,/usr/hdp/${hdp.version}/hadoop-client/lib/*,/usr/hdp/${hdp.version}/hadoop-hdfs-client/*,/usr/hdp/${hdp.version}/hadoop-hdfs-client/lib/*,/usr/hdp/${hdp.version}/hadoop-yarn-client/*,/usr/hdp/${hdp.version}/hadoop-yarn-client/lib/*"
      ryba.yarn.site['yarn.application.classpath'] ?= "$HADOOP_CONF_DIR,/usr/hdp/current/hadoop-client/*,/usr/hdp/current/hadoop-client/lib/*,/usr/hdp/current/hadoop-hdfs-client/*,/usr/hdp/current/hadoop-hdfs-client/lib/*,/usr/hdp/current/hadoop-yarn-client/*,/usr/hdp/current/hadoop-yarn-client/lib/*"
      # The default value of yarn.generic-application-history.save-non-am-container-meta-info
      # is true, so there is no change in behavior. For clusters with more than
      # 100 nodes, we recommend this configuration value be set to false to
      # reduce the load on the Application Timeline Service.
      # see http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.8/bk_HDP_RelNotes/content/behav-changes-228.html
      default_save_am_info = if yc_ctxs.length > 100 then 'false' else 'true'
      ryba.yarn.site['yarn.generic-application-history.save-non-am-container-meta-info'] ?= "#{default_save_am_info}"

## Yarn Timeline Server

      for property in [
        'yarn.timeline-service.enabled'
        'yarn.timeline-service.address'
        'yarn.timeline-service.webapp.address'
        'yarn.timeline-service.webapp.https.address'
        'yarn.timeline-service.principal'
        'yarn.timeline-service.http-authentication.type'
        'yarn.timeline-service.http-authentication.kerberos.principal'
      ]
        ryba.yarn.site[property] ?= if ats_ctx then ats_ctx.config.ryba.yarn.site[property] else null

      for nm_ctx in nm_ctxs
        for property in [
          # 'yarn.log-aggregation-enable'
          # 'yarn.log-aggregation.retain-check-interval-seconds'
          # 'yarn.log-aggregation.retain-seconds'
          'yarn.nodemanager.remote-app-log-dir'
        ]
          ryba.yarn.site[property] ?= nm_ctx.config.ryba.yarn.site[property]    

      for rm_ctx in rm_ctxs
        id = if rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.id']}" else ''
        for property in [
          'yarn.resourcemanager.principal'
          'yarn.http.policy'
          'yarn.log.server.url'
          'yarn.resourcemanager.cluster-id'
          # 'yarn.nodemanager.remote-app-log-dir'
          'yarn.resourcemanager.ha.enabled'
          'yarn.resourcemanager.ha.rm-ids'
          'yarn.resourcemanager.webapp.delegation-token-auth-filter.enabled'
          "yarn.resourcemanager.address#{id}"
          "yarn.resourcemanager.scheduler.address#{id}"
          "yarn.resourcemanager.admin.address#{id}"
          "yarn.resourcemanager.webapp.address#{id}"
          "yarn.resourcemanager.webapp.https.address#{id}"
        ]
          ryba.yarn.site[property] ?= rm_ctx.config.ryba.yarn.rm.site[property]

## FIX Companion Files

The "yarn-site.xml" file provided inside the companion files set some some
values that shall be overwritten by the user. This middleware ensures those
values don't get pushed to the cluster.

      unless @has_service 'ryba/hadoop/yarn_rm'
        ryba.yarn.site['yarn.scheduler.minimum-allocation-mb'] ?= null # Make sure we erase hdp default value
        ryba.yarn.site['yarn.scheduler.maximum-allocation-mb'] ?= null # Make sure we erase hdp default value
