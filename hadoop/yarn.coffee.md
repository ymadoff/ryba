---
title: 
layout: module
---

# YARN

    url = require 'url'
    misc = require 'mecano/lib/misc'
    mkcmd = require './lib/mkcmd'
    memory = require './lib/memory'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hadoop/core'

    module.exports.push module.exports.configure = (ctx) ->
      return if ctx.yarn_configured
      ctx.yarn_configured = true
      require('./hdfs').configure ctx
      {static_host, realm} = ctx.config.hdp
      # Grab the host(s) for each roles
      resourcemanager = ctx.host_with_module 'ryba/hadoop/yarn_rm'
      ctx.log "Resource manager: #{resourcemanager}"
      jobhistoryserver = ctx.host_with_module 'ryba/hadoop/mapred_jhs'
      ctx.log "Job History Server: #{jobhistoryserver}"
      ctx.config.hdp.yarn_log_dir ?= '/var/log/hadoop-yarn'         # /etc/hadoop/conf/yarn-env.sh#20
      ctx.config.hdp.yarn_pid_dir ?= '/var/run/hadoop-yarn'         # /etc/hadoop/conf/yarn-env.sh#21
      # Configure yarn
      # Comma separated list of paths. Use the list of directories from $YARN_LOCAL_DIR, eg: /grid/hadoop/hdfs/yarn/local,/grid1/hadoop/hdfs/yarn/local.
      throw new Error 'Required property: hdp.yarn[yarn.nodemanager.local-dirs]' unless ctx.config.hdp.yarn['yarn.nodemanager.local-dirs']
      # Use the list of directories from $YARN_LOCAL_LOG_DIR, eg: /grid/hadoop/yarn/logs /grid1/hadoop/yarn/logs /grid2/hadoop/yarn/logs
      throw new Error 'Required property: hdp.yarn[yarn.nodemanager.log-dirs]' unless ctx.config.hdp.yarn['yarn.nodemanager.log-dirs']
      ctx.config.hdp.yarn['yarn.resourcemanager.resource-tracker.address'] ?= "#{resourcemanager}:8025" # Enter your ResourceManager hostname.
      ctx.config.hdp.yarn['yarn.resourcemanager.scheduler.address'] ?= "#{resourcemanager}:8030" # Enter your ResourceManager hostname.
      ctx.config.hdp.yarn['yarn.resourcemanager.address'] ?= "#{resourcemanager}:8050" # Enter your ResourceManager hostname.
      ctx.config.hdp.yarn['yarn.resourcemanager.admin.address'] ?= "#{resourcemanager}:8141" # Enter your ResourceManager hostname.
      ctx.config.hdp.yarn['yarn.nodemanager.remote-app-log-dir'] ?= "/app-logs"
      ctx.config.hdp.yarn['yarn.log.server.url'] ?= "http://#{jobhistoryserver}:19888/jobhistory/logs/" # URL for job history server
      ctx.config.hdp.yarn['yarn.resourcemanager.webapp.address'] ?= "#{resourcemanager}:8088" # URL for job history server
      ctx.config.hdp.yarn['yarn.nodemanager.container-executor.class'] ?= 'org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor'
      ctx.config.hdp.yarn['yarn.nodemanager.linux-container-executor.group'] ?= 'yarn'
      # Required by yarn client
      ctx.config.hdp.yarn['yarn.resourcemanager.principal'] ?= "rm/#{static_host}@#{realm}"
      # Configurations for History Server (Needs to be moved elsewhere):
      ctx.config.hdp.yarn['yarn.log-aggregation.retain-seconds'] ?= '-1' #  How long to keep aggregation logs before deleting them. -1 disables. Be careful, set this too small and you will spam the name node.
      ctx.config.hdp.yarn['yarn.log-aggregation.retain-check-interval-seconds'] ?= '-1' # Time between checks for aggregated log retention. If set to 0 or a negative value then the value is computed as one-tenth of the aggregated log retention time. Be careful, set this too small and you will spam the name node.
      # [Container Executor](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Configuration_in_Secure_Mode)
      ctx.config.hdp.container_executor ?= {}
      ctx.config.hdp.container_executor['yarn.nodemanager.local-dirs'] ?= ctx.config.hdp.yarn['yarn.nodemanager.local-dirs']
      ctx.config.hdp.container_executor['yarn.nodemanager.linux-container-executor.group'] ?= ctx.config.hdp.yarn['yarn.nodemanager.linux-container-executor.group']
      ctx.config.hdp.container_executor['yarn.nodemanager.log-dirs'] = ctx.config.hdp.yarn['yarn.nodemanager.log-dirs']
      ctx.config.hdp.container_executor['banned.users'] ?= 'hfds,yarn,mapred,bin'
      ctx.config.hdp.container_executor['min.user.id'] ?= '0'
      # Cloudera recommand setting [vmem-check to false on Centos/RHEL 6 due to its aggressive allocation of virtual memory](http://blog.cloudera.com/blog/2014/04/apache-hadoop-yarn-avoiding-6-time-consuming-gotchas/)
      # yarn.nodemanager.vmem-check-enabled (found in hdfs-default.xml)
      # yarn.nodemanager.vmem-check.enabled


http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-9.html
http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode

    module.exports.push name: 'HDP YARN # Users & Groups', callback: (ctx, next) ->
      return next() unless ctx.config.hdp.resourcemanager or ctx.config.hdp.nodemanager
      {hadoop_group} = ctx.config.hdp
      ctx.execute
        cmd: "useradd yarn -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Hadoop YARN service\""
        code: 0
        code_skipped: 9
      , (err, executed) ->
        next err, if executed then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP YARN # Install Common', timeout: -1, callback: (ctx, next) ->
      ctx.service [
        name: 'hadoop'
      ,
        name: 'hadoop-yarn'
      ,
        name: 'hadoop-client'
      ], (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP YARN # Directories', timeout: -1, callback: (ctx, next) ->
      {yarn_user, hadoop_group, yarn_log_dir, yarn_pid_dir} = ctx.config.hdp
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
      , (err, created) ->
        next null, if created then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP YARN # Yarn OPTS', callback: (ctx, next) ->
      {yarn_user, hadoop_group, hadoop_conf_dir} = ctx.config.hdp
      yarn_opts = ""
      for k, v of ctx.config.hdp.yarn_opts
        yarn_opts += "-D#{k}=#{v} "
      yarn_opts = "YARN_OPTS=\"$YARN_OPTS #{yarn_opts}\" # ryba"
      ctx.config.hdp.yarn_opts = yarn_opts
      ctx.render
        source: "#{__dirname}/files/core_hadoop/yarn-env.sh"
        destination: "#{hadoop_conf_dir}/yarn-env.sh"
        local_source: true
        write: [
          match: /^.*ryba$/mg
          replace: yarn_opts
          append: 'yarn.policy.file'
        ]
        uid: yarn_user.name
        gid: hadoop_group.name
        mode: 0o0755
      , (err, rendered) ->
        next err, if rendered then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP YARN # Container Executor', callback: (ctx, next) ->
      modified = false
      {container_executor, hadoop_conf_dir} = ctx.config.hdp
      ce_group = container_executor['yarn.nodemanager.linux-container-executor.group']
      container_executor = misc.merge {}, container_executor
      container_executor['yarn.nodemanager.local-dirs'] = container_executor['yarn.nodemanager.local-dirs'].join ','
      container_executor['yarn.nodemanager.log-dirs'] = container_executor['yarn.nodemanager.log-dirs'].join ','
      do_stat = ->
        ce = '/usr/lib/hadoop-yarn/bin/container-executor';
        ctx.log "change ownerships and permissions to '#{ce}'"
        ctx.chown
          destination: ce
          uid: 'root'
          gid: ce_group
        , (err, chowned) ->
          return next err if err
          modified = true if chowned
          ctx.chmod
            destination: ce
            mode: 0o6050
          , (err, chmoded) ->
            return next err if err
            modified = true if chmoded
            do_conf()
      do_conf = ->
        ctx.log "Write to '#{hadoop_conf_dir}/container-executor.cfg' as ini"
        ctx.ini
          destination: "#{hadoop_conf_dir}/container-executor.cfg"
          content: container_executor
          uid: 'root'
          gid: ce_group
          mode: 0o0640
          separator: '='
          backup: true
        , (err, inied) ->
          modified = true if inied
          next err, if modified then ctx.OK else ctx.PASS
      do_stat()

    module.exports.push name: 'HDP YARN # Configuration', callback: (ctx, next) ->
      { yarn, hadoop_conf_dir, capacity_scheduler } = ctx.config.hdp
      modified = false
      do_yarn = ->
        ctx.log 'Configure yarn-site.xml'
        config = {}
        for k,v of yarn then config[k] = v 
        config['yarn.nodemanager.local-dirs'] = config['yarn.nodemanager.local-dirs'].join ',' if Array.isArray yarn['yarn.nodemanager.local-dirs']
        config['yarn.nodemanager.log-dirs'] = config['yarn.nodemanager.log-dirs'].join ',' if Array.isArray yarn['yarn.nodemanager.log-dirs']
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/yarn-site.xml"
          default: "#{__dirname}/files/core_hadoop/yarn-site.xml"
          local_default: true
          properties: config
          merge: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_capacity_scheduler()
      do_capacity_scheduler = ->
        ctx.log 'Configure capacity-scheduler.xml'
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/capacity-scheduler.xml"
          default: "#{__dirname}/files/core_hadoop/capacity-scheduler.xml"
          local_default: true
          properties: capacity_scheduler
          merge: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_end()
      do_end = ->
        next null, if modified then ctx.OK else ctx.PASS
      do_yarn()

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

    module.exports.push name: 'HDP YARN # Memory Allocation', callback: module.exports.tuning = (ctx, next) ->
      {hadoop_conf_dir} = ctx.config.hdp
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
      , (err, configured) ->
        return next err, if configured then ctx.OK else ctx.PASS

    # module.exports.push name: 'HDP YARN # Memory Allocation', callback: module.exports.tuning = (ctx, next) ->
    #   {yarn, hadoop_conf_dir} = ctx.config.hdp
    #   yarn_site = yarn
    #   # yarn.scheduler.maximum-allocation-mb
    #   # yarn.nodemanager.log.retain-seconds (cherif mettre la valeur à 10800 au lie de 604800)
    #   # yarn.log-aggregation.retain-seconds (chefrif)

    #   # Follow [Hortonworks example](http://hortonworks.com/blog/how-to-plan-and-configure-yarn-in-hdp-2-0/)
    #   # As a general recommendation, Hortonworks found that allowing for 1-2 
    #   # Containers per disk and per core gives the best balance for cluster utilization.
    #   # Each machine in our cluster has 96 GB of RAM. Some of this RAM should be 
    #   # reserved for Operating System usage. On each node, we’ll reserve 10% 
    #   # with a maximum of 8 GB for the Operating System.
    #   numberOfCores = Math.floor ctx.cpuinfo.length
    #   memTotalMb = Math.floor ctx.meminfo.MemTotal / 1000 / 1000
    #   reserved = Math.round(memTotalMb * 0.1)
    #   max_reserved = 8*1024
    #   reserved = max_reserved if reserved > max_reserved
    #   memory = yarn_site['yarn.nodemanager.resource.memory-mb'] ?= "#{memTotalMb-reserved}"
    #   # We provide YARN guidance on how to break up the total resources 
    #   # available into Containers by specifying the minimum unit of RAM to 
    #   # allocate for a Container. . We have 12 disk, experience suggest that a 
    #   # ratio between 1 and 2 container per disk, so we want to allow for a 
    #   # maximum of 20 Containers, and thus need (40 GB total RAM) / (20 # of 
    #   # Containers) = 2 GB minimum per container
    #   # minimum of (2*CORES, 1.8*DISKS, (Total available RAM) / MIN_CONTAINER_SIZE) (http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.9.1/bk_installing_manually_book/content/rpm-chap1-11.html)
    #   containers = Math.floor Math.min numberOfCores*2, yarn_site['yarn.nodemanager.local-dirs'].length * 1.8, (memory / getMininumContainerSize memory)
    #   memory_minimum = yarn_site['yarn.scheduler.minimum-allocation-mb'] ?= Math.floor(memory / containers)
    #   # Note, "yarn.scheduler.maximum-allocation-mb" default to 8192 in yarn-site.xml and to 6144 in HDP companion files
    #   # Maximum memory estimation is 3 times the minimum memory, while not exceding the total memory and with a minimum of 6144
    #   # memory_maximum = yarn_site['yarn.scheduler.maximum-allocation-mb'] ?= Math.min memory, Math.max 6144, memory_minimum * 3
    #   memory_maximum = yarn_site['yarn.scheduler.maximum-allocation-mb'] ?= memory
    #   # yarn_site['yarn.scheduler.maximum-allocation-mb'] = 6144
    #   ratio = yarn_site['yarn.nodemanager.vmem-pmem-ratio'] ?= "2.1" # also defined by ryba/hadoop/mapred
    #   # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.9.1/bk_installing_manually_book/content/rpm-chap1-11.html
    #   yarn_site['yarn.app.mapreduce.am.resource.mb'] ?= Math.min memory, Math.floor 2 * memory_minimum # 2 * RAM-per-Container
    #   yarn_site['yarn.app.mapreduce.am.command-opts'] ?= Math.min memory, Math.floor 0.8 * 2 * memory_minimum # = 0.8 * 2 * RAM-per-Container 
    #   # Log result
    #   ctx.log "Server memory: #{memTotalMb} mb"
    #   ctx.log "Yarn available memory: #{memory} mb (yarn.nodemanager.resource.memory-mb)"
    #   ctx.log "Number of containers: #{containers}"
    #   ctx.log "Minimum memory allocation: #{memory_minimum} mb (yarn.scheduler.minimum-allocation-mb)"
    #   ctx.log "Maximum memory allocation: #{memory_maximum} mb (yarn.scheduler.maximum-allocation-mb)"
    #   ctx.hconfigure
    #     destination: "#{hadoop_conf_dir}/yarn-site.xml"
    #     properties:
    #       'yarn.nodemanager.vmem-pmem-ratio': ratio
    #       'yarn.nodemanager.resource.memory-mb': memory
    #       'yarn.scheduler.minimum-allocation-mb': memory_minimum
    #       'yarn.scheduler.maximum-allocation-mb': memory_maximum
    #     merge: true
    #   , (err, configured) ->
    #     return next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP YARN # Keytabs Directory', timeout: -1, callback: (ctx, next) ->
      ctx.mkdir
        destination: '/etc/security/keytabs'
        uid: 'root'
        gid: 'hadoop'
        mode: 0o750
      , (err, created) ->
        next null, if created then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP YARN # Configure Kerberos', callback: (ctx, next) ->
      {hadoop_conf_dir, static_host, realm} = ctx.config.hdp
      yarn = {}
      # Todo: might need to configure WebAppProxy but I understood that it is run as part of rm if not configured separately
      # yarn.web-proxy.address    WebAppProxy                                   host:port for proxy to AM web apps. host:port if this is the same as yarn.resourcemanager.webapp.address or it is not defined then the ResourceManager will run the proxy otherwise a standalone proxy server will need to be launched.
      # yarn.web-proxy.keytab     /etc/security/keytabs/web-app.service.keytab  Kerberos keytab file for the WebAppProxy.
      # yarn.web-proxy.principal  wap/_HOST@REALM.TLD                           Kerberos principal name for the WebAppProxy.
      # Todo: need to deploy "container-executor.cfg"
      # see http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode
      # Configurations the ResourceManager
      yarn['yarn.resourcemanager.keytab'] ?= '/etc/security/keytabs/rm.service.keytab'
      # Configurations for NodeManager:
      yarn['yarn.nodemanager.keytab'] ?= '/etc/security/keytabs/nm.service.keytab'
      yarn['yarn.nodemanager.principal'] ?= "nm/#{static_host}@#{realm}"
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        properties: yarn
        merge: true
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

### HDFS Layout

Create the YARN log directory defined by the property 
"yarn.nodemanager.remote-app-log-dir". The default value in the HDP companion
files is "/app-logs". The command `hdfs dfs -ls /` should print:

```
drwxrwxrwt   - yarn   hdfs            0 2014-05-26 11:01 /app-logs
```

Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)

    module.exports.push name: 'HDP YARN # HDFS layout', callback: (ctx, next) ->
      {yarn, yarn_user} = ctx.config.hdp
      ok = false
      do_remote_app_log_dir = ->
        remote_app_log_dir = yarn['yarn.nodemanager.remote-app-log-dir']
        ctx.log "Create #{remote_app_log_dir}"
        ctx.execute
          cmd: mkcmd.hdfs ctx, """
          if hdfs dfs -test -d #{remote_app_log_dir}; then exit 1; fi
          hdfs dfs -mkdir -p #{remote_app_log_dir}
          hdfs dfs -chown #{yarn_user.name} #{remote_app_log_dir}
          hdfs dfs -chmod 1777 #{remote_app_log_dir}
          """
          code_skipped: 1
        , (err, executed, stdout) ->
          return next err if err
          ok = true if executed
          do_end()
      do_end = ->
        next null, if ok then ctx.OK else ctx.PASS
      do_remote_app_log_dir()











