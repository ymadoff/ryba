
# YARN NodeManager

The NodeManager (NM) is YARN’s per-node agent, and takes care of the individual
compute nodes in a Hadoop cluster. This includes keeping up-to date with the
ResourceManager (RM), overseeing containers’ life-cycle management; monitoring
resource usage (memory, CPU) of individual containers, tracking node-health,
log’s management and auxiliary services which may be exploited by different YARN
applications.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('./yarn').configure ctx
      {host, ryba} = ctx.config
      ryba.yarn.site['yarn.nodemanager.address'] ?= "#{host}:45454"
      ryba.yarn.site['yarn.nodemanager.localizer.address'] ?= "#{host}:8040"
      ryba.yarn.site['yarn.nodemanager.webapp.address'] ?= "#{host}:8042"
      ryba.yarn.site['yarn.nodemanager.webapp.https.address'] ?= "#{host}:8044"
      ryba.yarn.site['yarn.nodemanager.container-executor.class'] ?= 'org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor'
      ryba.yarn.site['yarn.nodemanager.linux-container-executor.group'] ?= 'yarn'
      ryba.yarn.site['yarn.nodemanager.remote-app-log-dir'] ?= "/app-logs"
      ryba.yarn.site['yarn.nodemanager.keytab'] ?= '/etc/security/keytabs/nm.service.keytab'
      ryba.yarn.site['yarn.nodemanager.principal'] ?= "nm/#{ryba.static_host}@#{ryba.realm}"
      # See '~/www/src/hadoop/hadoop-common/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-api/src/main/java/org/apache/hadoop/yarn/conf/YarnConfiguration.java#263'
      # ryba.yarn.site['yarn.nodemanager.webapp.spnego-principal']
      # ryba.yarn.site['yarn.nodemanager.webapp.spnego-keytab-file']
      # Cloudera recommand setting [vmem-check to false on Centos/RHEL 6 due to its aggressive allocation of virtual memory](http://blog.cloudera.com/blog/2014/04/apache-hadoop-yarn-avoiding-6-time-consuming-gotchas/)
      # yarn.nodemanager.vmem-check-enabled (found in hdfs-default.xml)
      # yarn.nodemanager.vmem-check.enabled
      # [Container Executor](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Configuration_in_Secure_Mode)
      ryba.container_executor ?= {}
      ryba.container_executor['yarn.nodemanager.local-dirs'] ?= ryba.yarn.site['yarn.nodemanager.local-dirs']
      ryba.container_executor['yarn.nodemanager.linux-container-executor.group'] ?= ryba.yarn.site['yarn.nodemanager.linux-container-executor.group']
      ryba.container_executor['yarn.nodemanager.log-dirs'] = ryba.yarn.site['yarn.nodemanager.log-dirs']
      ryba.container_executor['banned.users'] ?= 'hfds,yarn,mapred,bin'
      ryba.container_executor['min.user.id'] ?= '0'

    # module.exports.push commands: 'backup', modules: 'ryba/hadoop/yarn_nm_backup'

    # module.exports.push commands: 'check', modules: 'ryba/hadoop/yarn_nm_check'

    module.exports.push commands: 'report', modules: 'ryba/hadoop/yarn_nm_report'
    module.exports.push commands: 'install', modules: 'ryba/hadoop/yarn_nm_install'

    module.exports.push commands: 'start', modules: 'ryba/hadoop/yarn_nm_start'

    module.exports.push commands: 'status', modules: 'ryba/hadoop/yarn_nm_status'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/yarn_nm_stop'



