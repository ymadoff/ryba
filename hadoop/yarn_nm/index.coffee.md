
# YARN NodeManager

[The NodeManager](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/YARN.htm) (NM) is YARN’s per-node agent,
and takes care of the individual
computing nodes in a Hadoop cluster. This includes keeping up-to date with the
ResourceManager (RM), overseeing containers’ life-cycle management; monitoring
resource usage (memory, CPU) of individual containers, tracking node-health,
log’s management and auxiliary services which may be exploited by different YARN
applications.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('../yarn_client').configure ctx
      {host, ryba} = ctx.config

      # Working Directories (see capacity for server resource discovery)
      ryba.yarn.site['yarn.nodemanager.local-dirs'] ?= ['/var/yarn/local']
      ryba.yarn.site['yarn.nodemanager.local-dirs'] = ryba.yarn.site['yarn.nodemanager.local-dirs'].join ',' if Array.isArray ryba.yarn.site['yarn.nodemanager.local-dirs']
      ryba.yarn.site['yarn.nodemanager.log-dirs'] ?= ['/var/yarn/logs']
      ryba.yarn.site['yarn.nodemanager.log-dirs'] = ryba.yarn.site['yarn.nodemanager.log-dirs'].join ',' if Array.isArray ryba.yarn.site['yarn.nodemanager.log-dirs']
      # Configuration
      # ryba.yarn.site['yarn.scheduler.minimum-allocation-mb'] ?= null # Make sure we erase hdp default value
      # ryba.yarn.site['yarn.scheduler.maximum-allocation-mb'] ?= null # Make sure we erase hdp default value
      ryba.yarn.site['yarn.nodemanager.address'] ?= "#{host}:45454"
      ryba.yarn.site['yarn.nodemanager.localizer.address'] ?= "#{host}:8040"
      ryba.yarn.site['yarn.nodemanager.webapp.address'] ?= "#{host}:8042"
      ryba.yarn.site['yarn.nodemanager.webapp.https.address'] ?= "#{host}:8044"
      ryba.yarn.site['yarn.nodemanager.container-executor.class'] ?= 'org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor'
      ryba.yarn.site['yarn.nodemanager.linux-container-executor.group'] ?= 'yarn'
      ryba.yarn.site['yarn.nodemanager.remote-app-log-dir'] ?= "/app-logs"
      ryba.yarn.site['yarn.nodemanager.keytab'] ?= '/etc/security/keytabs/nm.service.keytab'
      ryba.yarn.site['yarn.nodemanager.principal'] ?= "nm/#{ryba.static_host}@#{ryba.realm}"
      ryba.yarn.site['yarn.nodemanager.vmem-pmem-ratio'] ?= '2.1'
      # See '~/www/src/hadoop/hadoop-common/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-api/src/main/java/org/apache/hadoop/yarn/conf/YarnConfiguration.java#263'
      # ryba.yarn.site['yarn.nodemanager.webapp.spnego-principal']
      # ryba.yarn.site['yarn.nodemanager.webapp.spnego-keytab-file']
      # Cloudera recommand setting [vmem-check to false on Centos/RHEL 6 due to its aggressive allocation of virtual memory](http://blog.cloudera.com/blog/2014/04/apache-hadoop-yarn-avoiding-6-time-consuming-gotchas/)
      # by default, "yarn.nodemanager.vmem-check-enabled" is true (see in yarn-default.xml)
      # [Container Executor](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Configuration_in_Secure_Mode)
      ryba.container_executor ?= {}
      ryba.container_executor['yarn.nodemanager.local-dirs'] ?= ryba.yarn.site['yarn.nodemanager.local-dirs']
      ryba.container_executor['yarn.nodemanager.linux-container-executor.group'] ?= ryba.yarn.site['yarn.nodemanager.linux-container-executor.group']
      ryba.container_executor['yarn.nodemanager.log-dirs'] = ryba.yarn.site['yarn.nodemanager.log-dirs']
      ryba.container_executor['banned.users'] ?= 'hfds,yarn,mapred,bin'
      ryba.container_executor['min.user.id'] ?= '0'

## Configuration for CGroups

Resources:
*   [YARN-600: Hook up cgroups CPU settings to the number of virtual cores allocated](https://issues.apache.org/jira/browse/YARN-600)
*   [YARN-810: CGroup ceiling enforcement on CPU](https://issues.apache.org/jira/browse/YARN-810)
*   [Using YARN with Cgroups](http://riccomini.name/posts/hadoop/2013-06-14-yarn-with-cgroups/)
*   [VCore Configuration In Hadoop](http://jason4zhu.blogspot.fr/2014/10/vcore-configuration-in-hadoop.html)

      isLinuxContainer = ryba.yarn.site['yarn.nodemanager.container-executor.class'] is 'org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor'
      # if isLinuxContainer and ctx.has_any_modules 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm'
      ryba.yarn.site['yarn.nodemanager.linux-container-executor.resources-handler.class'] ?= 'org.apache.hadoop.yarn.server.nodemanager.util.CgroupsLCEResourcesHandler'
      ryba.yarn.site['yarn.nodemanager.linux-container-executor.cgroups.hierarchy'] ?= '/hadoop-yarn'
      ryba.yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount'] ?= 'true'
      ryba.yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount-path'] ?= '/cgroup'

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/hadoop/yarn_nm/backup'

    # module.exports.push commands: 'check', modules: 'ryba/hadoop/yarn_nm/check'

    module.exports.push commands: 'report', modules: 'ryba/hadoop/yarn_nm/report'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/yarn_nm/install'
      'ryba/hadoop/yarn_nm/start'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hadoop/yarn_nm/start'

    module.exports.push commands: 'status', modules: 'ryba/hadoop/yarn_nm/status'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/yarn_nm/stop'



