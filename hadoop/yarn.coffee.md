---
title: 
layout: module
---

# YARN

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/core'

    module.exports.push module.exports.configure = (ctx) ->
      return if ctx.yarn_configured
      ctx.yarn_configured = true
      require('masson/commons/java').configure ctx
      require('./hdfs').configure ctx
      {ryba} = ctx.config
      {static_host, realm} = ryba
      # Grab the host(s) for each roles
      resourcemanager = ctx.host_with_module 'ryba/hadoop/yarn_rm'
      jobhistoryserver = ctx.host_with_module 'ryba/hadoop/mapred_jhs'
      ryba.yarn_log_dir ?= '/var/log/hadoop-yarn'         # /etc/hadoop/conf/yarn-env.sh#20
      ryba.yarn_pid_dir ?= '/var/run/hadoop-yarn'         # /etc/hadoop/conf/yarn-env.sh#21
      # Configure yarn
      # Comma separated list of paths. Use the list of directories from $YARN_LOCAL_DIR, eg: /grid/hadoop/hdfs/yarn/local,/grid1/hadoop/hdfs/yarn/local.
      throw new Error 'Required property: hdp.yarn_site[yarn.nodemanager.local-dirs]' unless ryba.yarn_site['yarn.nodemanager.local-dirs']
      # Use the list of directories from $YARN_LOCAL_LOG_DIR, eg: /grid/hadoop/yarn/logs /grid1/hadoop/yarn/logs /grid2/hadoop/yarn/logs
      throw new Error 'Required property: hdp.yarn_site[yarn.nodemanager.log-dirs]' unless ryba.yarn_site['yarn.nodemanager.log-dirs']
      ryba.yarn_site['yarn.http.policy'] ?= 'HTTPS_ONLY'
      ryba.yarn_site['yarn.resourcemanager.resource-tracker.address'] ?= "#{resourcemanager}:8025" # Enter your ResourceManager hostname.
      ryba.yarn_site['yarn.resourcemanager.scheduler.address'] ?= "#{resourcemanager}:8030" # Enter your ResourceManager hostname.
      ryba.yarn_site['yarn.resourcemanager.address'] ?= "#{resourcemanager}:8050" # Enter your ResourceManager hostname.
      ryba.yarn_site['yarn.resourcemanager.admin.address'] ?= "#{resourcemanager}:8141" # Enter your ResourceManager hostname.
      ryba.yarn_site['yarn.log.server.url'] ?= "http://#{jobhistoryserver}:19888/jobhistory/logs/" # URL for job history server
      ryba.yarn_site['yarn.resourcemanager.webapp.address'] ?= "#{resourcemanager}:8088" # URL for job history server
      ryba.yarn_site['yarn.resourcemanager.webapp.https.address'] ?= "#{resourcemanager}:8090"
      # Required by yarn client
      ryba.yarn_site['yarn.resourcemanager.principal'] ?= "rm/#{static_host}@#{realm}"
      # Configurations for History Server (Needs to be moved elsewhere):
      ryba.yarn_site['yarn.log-aggregation.retain-seconds'] ?= '-1' #  How long to keep aggregation logs before deleting them. -1 disables. Be careful, set this too small and you will spam the name node.
      ryba.yarn_site['yarn.log-aggregation.retain-check-interval-seconds'] ?= '-1' # Time between checks for aggregated log retention. If set to 0 or a negative value then the value is computed as one-tenth of the aggregated log retention time. Be careful, set this too small and you will spam the name node.

http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-9.html
http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode

    module.exports.push name: 'Hadoop YARN # Users & Groups', callback: (ctx, next) ->
      return next() unless ctx.config.ryba.resourcemanager or ctx.config.ryba.nodemanager
      {yarn_user, hadoop_group} = ctx.config.ryba
      ctx.execute
        cmd: "useradd #{yarn_user.name} -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Hadoop YARN service\""
        code: 0
        code_skipped: 9
      , next

    module.exports.push name: 'Hadoop YARN # Install Common', timeout: -1, callback: (ctx, next) ->
      ctx.service [
        name: 'hadoop'
      ,
        name: 'hadoop-yarn'
      ,
        name: 'hadoop-client'
      ], next

    module.exports.push name: 'Hadoop YARN # Directories', timeout: -1, callback: (ctx, next) ->
      {yarn_user, hadoop_group, yarn_log_dir, yarn_pid_dir} = ctx.config.ryba
      ctx.mkdir
        destination: "#{yarn_log_dir}/#{yarn_user.name}"
        uid: yarn_user.name
        gid: hadoop_group.name
        mode: 0o0755
      ,
        destination: "#{yarn_pid_dir}/#{yarn_user.name}"
        uid: yarn_user.name
        gid: hadoop_group.name
        mode: 0o0755
      , next

    module.exports.push name: 'Hadoop YARN # Yarn OPTS', callback: (ctx, next) ->
      {java_home} = ctx.config.java
      {yarn_user, hadoop_group, hadoop_conf_dir} = ctx.config.ryba
      yarn_opts = ""
      for k, v of ctx.config.ryba.yarn_opts
        yarn_opts += "-D#{k}=#{v} "
      yarn_opts = "YARN_OPTS=\"$YARN_OPTS #{yarn_opts}\" # ryba"
      ctx.config.ryba.yarn_opts = yarn_opts
      ctx.render
        source: "#{__dirname}/../resources/core_hadoop/yarn-env.sh"
        destination: "#{hadoop_conf_dir}/yarn-env.sh"
        local_source: true
        write: [
          match: /^export JAVA_HOME=.*$/mg
          replace: "export JAVA_HOME=#{java_home}"
        ,
          match: /^.*ryba$/mg
          replace: yarn_opts
          append: 'yarn.policy.file'
        ]
        uid: yarn_user.name
        gid: hadoop_group.name
        mode: 0o0755
      , next

    module.exports.push name: 'Hadoop YARN # Configuration', callback: (ctx, next) ->
      {yarn_site, hadoop_conf_dir} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        default: "#{__dirname}/../resources/core_hadoop/yarn-site.xml"
        local_default: true
        properties: yarn_site
        merge: true
      , next

## HDP YARN # Memory Allocation

yarn.nodemanager.vmem-pmem-ratio property: Is defines ratio of virtual memory to
available pysical memory, Here is 2.1 means virtual memory will be double the 
size of physical memory.

yarn.app.mapreduce.am.command-opts: In yarn ApplicationMaster(AM) is responsible
for securing necessary resources. So this property defines how much memory 
required to run AM itself. Don't confuse this with nodemanager, where job will 
be executed.

yarn.app.mapreduce.am.resource.mb: This property specify criteria to select 
resource for particular job. Here is given 1536 Means any nodemanager which has 
equal or more memory available will get selected for executing job.

Ressources:
http://stackoverflow.com/questions/18692631/difference-between-3-memory-parameters-in-hadoop-2
blog.cloudera.com/blog/2014/04/apache-hadoop-yarn-avoiding-6-time-consuming-gotchas/

TODO, got to [HortonWorks article and make properties dynamic or improve example](http://hortonworks.com/blog/how-to-plan-and-configure-yarn-in-hdp-2-0/)

Example cluster node with 12 disks and 12 cores, we will allow for 20 maximum Containers to be allocated to each node

    module.exports.push name: 'Hadoop YARN # Memory Allocation', callback: module.exports.tuning = (ctx, next) ->
      {hadoop_conf_dir} = ctx.config.ryba
      {info, yarn_site} = memory ctx
      ctx.log "Server memory: #{info.memoryTotalMb} mb"
      ctx.log "Available memory: #{info.memoryAvailableMb} mb"
      ctx.log "Yarn total memory: #{yarn_site['yarn.nodemanager.resource.memory-mb']} mb"
      ctx.log "Number of containers: #{info.maxNumberOfcontainers}"
      ctx.log "Minimum memory allocation: #{yarn_site['yarn.scheduler.minimum-allocation-mb']} mb (yarn.scheduler.minimum-allocation-mb)"
      ctx.log "Maximum memory allocation: #{yarn_site['yarn.scheduler.maximum-allocation-mb']} mb (yarn.scheduler.maximum-allocation-mb)"
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        properties: yarn_site
        merge: true
      , next

    module.exports.push name: 'Hadoop YARN # Configure Kerberos', callback: (ctx, next) ->
      {hadoop_conf_dir, static_host, realm} = ctx.config.ryba
      yarn_site = {}
      # Todo: need to deploy "container-executor.cfg"
      # see http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode
      # Configurations the ResourceManager
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        properties: yarn_site
        merge: true
      , next

## Module Dependencies

    memory = require '../lib/memory'











