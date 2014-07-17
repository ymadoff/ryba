---
title: 
layout: module
---

# MapRed

    url = require 'url'
    mkcmd = require './lib/mkcmd'
    memory = require './lib/memory'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/hadoop/hdfs'

    module.exports.push module.exports.configure = (ctx) ->
      return if ctx.mapred_configured
      ctx.mapred_configured = true
      require('./hdfs').configure ctx
      require('./yarn').configure ctx
      require('./mapred_').configure ctx
      {static_host, realm, mapred} = ctx.config.hdp
      jhs_host = ctx.host_with_module 'ryba/hadoop/mapred_jhs'
      # Layout
      ctx.config.hdp.mapred_pid_dir ?= '/var/run/hadoop-mapreduce'  # /etc/hadoop/conf/hadoop-env.sh#94
      # Configuration
      mapred['mapreduce.job.counters.max'] ?= 120
      # Not sure if we need this, at this time, the directory isnt created
      mapred['mapreduce.jobtracker.system.dir'] ?= '/mapred/system'
      mapred['mapreduce.reduce.shuffle.parallelcopies'] ?= '50' #  Higher number of parallel copies run by reduces to fetch outputs from very large number of maps.
      # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.6.0/bk_installing_manually_book/content/rpm_chap3.html
      # Optional: Configure MapReduce to use Snappy Compression
      # Complement core-site.xml configuration
      mapred['mapreduce.admin.map.child.java.opts'] ?= "-server -XX:NewRatio=8 -Djava.library.path=/usr/lib/hadoop/lib/native/ -Djava.net.preferIPv4Stack=true"
      mapred['mapreduce.admin.reduce.child.java.opts'] ?= "-server -XX:NewRatio=8 -Djava.library.path=/usr/lib/hadoop/lib/native/ -Djava.net.preferIPv4Stack=true"
      # [Configurations for MapReduce JobHistory Server](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Configuring_the_Hadoop_Daemons_in_Non-Secure_Mode)
      mapred['mapreduce.jobhistory.address'] ?= "#{jhs_host}:10020" # MapReduce JobHistory Server host:port - Default port is 10020.
      mapred['mapreduce.jobhistory.webapp.address'] ?= "#{jhs_host}:19888" # MapReduce JobHistory Server Web UI host:port - Default port is 19888.
      mapred['mapreduce.jobhistory.done-dir'] ?= '/mr-history/done' # Directory where history files are managed by the MR JobHistory Server.
      mapred['mapreduce.jobhistory.intermediate-done-dir'] ?= '/mr-history/tmp' # Directory where history files are written by MapReduce jobs.
      # Important, JHS principal must be deployed on all mapreduce workers
      mapred['mapreduce.jobhistory.principal'] ?= "jhs/#{jhs_host}@#{realm}"
      #mapred['mapreduce.jobhistory.principal'] ?= "jhs/#{static_host}@#{realm}"

## IPTables

| Service          | Port  | Proto | Parameter                           |
|------------------|-------|-------|-------------------------------------|
| jobhistory | 10020 | http  | mapreduce.jobhistory.address        |
| jobhistory | 19888 | tcp   | mapreduce.jobhistory.webapp.address |
| jobhistory | 13562 | tcp   | mapreduce.shuffle.port              |


IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'HDP MapRed # IPTables', callback: (ctx, next) ->
      {mapred} = ctx.config.hdp
      jobclient = mapred['yarn.app.mapreduce.am.job.client.port-range']
      jobclient = jobclient.replace '-', ':'
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: jobclient, protocol: 'tcp', state: 'NEW', comment: "MapRed Client Range" }
        ]
        if: ctx.config.iptables.action is 'start'
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP MapRed # Install Common', timeout: -1, callback: (ctx, next) ->
      ctx.service [
        name: 'hadoop'
      ,
        name: 'hadoop-mapreduce'
      ,
        name: 'hadoop-client'
      ], (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-9.html
http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode

    module.exports.push name: 'HDP MapRed # Users & Groups', callback: (ctx, next) ->
      {hadoop_group} = ctx.config.hdp
      ctx.execute
        cmd: "useradd mapred -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Hadoop MapReduce service\""
        code: 0
        code_skipped: 9
      , (err, executed) ->
        next err, if executed then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP MapRed # System Directories', timeout: -1, callback: (ctx, next) ->
      { mapred_user, hadoop_group, mapred_log_dir, mapred_pid_dir } = ctx.config.hdp
      modified = false
      do_log = ->
        ctx.log "Create hdfs and mapred log: #{mapred_log_dir}"
        ctx.mkdir
          destination: "#{mapred_log_dir}/#{mapred_user.name}"
          uid: mapred_user.name
          gid: hadoop_group.name
          mode: 0o0755
        , (err, created) ->
          return next err if err
          modified = true if created
          do_pid()
      do_pid = ->
        ctx.log "Create hdfs and mapred pid: #{mapred_pid_dir}"
        ctx.mkdir
          destination: "#{mapred_pid_dir}/#{mapred_user.name}"
          uid: mapred_user.name
          gid: hadoop_group.name
          mode: 0o0755
        , (err, created) ->
          return next err if err
          modified = true if created
          do_end()
      do_end = ->
        next null, if modified then ctx.OK else ctx.PASS
      do_log()

    module.exports.push name: 'HDP MapRed # Configuration', callback: (ctx, next) ->
      { mapred, hadoop_conf_dir, mapred_user, mapred_group, mapred_queue_acls } = ctx.config.hdp
      modified = false
      do_mapred = ->
        ctx.log 'Configure mapred-site.xml'
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/mapred-site.xml"
          default: "#{__dirname}/files/core_hadoop/mapred-site.xml"
          local_default: true
          properties: mapred
          merge: true
          uid: mapred_user.name
          gid: mapred_group.name
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_mapred_queue_acls()
      do_mapred_queue_acls = ->
        ctx.log 'Configure mapred-queue-acls.xml'
        # Note, HDP-1.3.1 official doc is awkward, the example show an xml file.
        # http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.1/bk_installing_manually_book/content/rpm_chap3.html
        # The file is present inside HDP-2.0
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/mapred-queue-acls.xml"
          default: "#{__dirname}/files/core_hadoop/mapred-queue-acls.xml"
          local_default: true
          properties: mapred_queue_acls
          merge: true
          uid: mapred_user.name
          gid: mapred_group.name
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_end()
      do_end = ->
        next null, if modified then ctx.OK else ctx.PASS
      do_mapred()

## HDP MapRed # Tuning

There are three aspects to consider:

*   Physical RAM limit for each Map And Reduce task
*   The JVM heap size limit for each task
*   The amount of virtual memory each task will get

The maximum memory each Map and Reduce task should be at least equal to or more 
than the YARN minimum Container allocation.

The JVM heap size should be set to lower than the Map and Reduce memory defined 
above, so that they are within the bounds of the Container memory allocated by 
YARN. There set by default to 3/4 of the YARN minimum Container allocation.

The virtual memory (physical + paged memory) upper limit for each Map and 
Reduce task is determined by the virtual memory ratio each YARN Container is 
allowed.

    module.exports.push name: 'HDP MapRed # Tuning', callback: (ctx, next) ->
      {hadoop_conf_dir} = ctx.config.hdp
      {info, mapred_site} = memory ctx
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/mapred-site.xml"
        properties: mapred_site
        backup: true
        merge: true
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS





