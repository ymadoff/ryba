---
title: 
layout: module
---

# MapRed Install

    url = require 'url'
    mkcmd = require '../lib/mkcmd'
    memory = require '../lib/memory'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/hadoop/hdfs_client'
    module.exports.push 'ryba/hadoop/yarn_client'

    module.exports.push require('./mapred_client').configure

## IPTables

| Service    | Port        | Proto | Parameter                                   |
|------------|-------------|-------|---------------------------------------------|
| mapreduce  | 59100-59200 | http  | yarn.app.mapreduce.am.job.client.port-range |


IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'Hadoop MapRed # IPTables', callback: (ctx, next) ->
      {mapred_site} = ctx.config.ryba
      jobclient = mapred_site['yarn.app.mapreduce.am.job.client.port-range']
      jobclient = jobclient.replace '-', ':'
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: jobclient, protocol: 'tcp', state: 'NEW', comment: "MapRed Client Range" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

    module.exports.push name: 'Hadoop MapRed # Install Common', timeout: -1, callback: (ctx, next) ->
      ctx.service [
        name: 'hadoop'
      ,
        name: 'hadoop-mapreduce'
      ,
        name: 'hadoop-client'
      ], next

http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-9.html
http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode

    module.exports.push name: 'Hadoop MapRed # Users & Groups', callback: (ctx, next) ->
      {mapred_user, hadoop_group} = ctx.config.ryba
      ctx.execute
        cmd: "useradd #{mapred_user.name} -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Hadoop MapReduce service\""
        code: 0
        code_skipped: 9
      , next

    module.exports.push name: 'Hadoop MapRed # System Directories', timeout: -1, callback: (ctx, next) ->
      { mapred_user, hadoop_group, mapred_log_dir, mapred_pid_dir } = ctx.config.ryba
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
        next null, modified
      do_log()

    module.exports.push name: 'Hadoop MapRed # Configuration', callback: (ctx, next) ->
      { mapred_site, hadoop_conf_dir, mapred_user, mapred_group, mapred_queue_acls } = ctx.config.ryba
      modified = false
      do_mapred = ->
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/mapred-site.xml"
          default: "#{__dirname}/../resources/core_hadoop/mapred-site.xml"
          local_default: true
          properties: mapred_site
          merge: true
          backup: true
          uid: mapred_user.name
          gid: mapred_group.name
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_mapred_queue_acls()
      do_mapred_queue_acls = ->
        # TODO: remove, replaced by capacity scheduler
        # Note, HDP-1.3.1 official doc is awkward, the example show an xml file.
        # http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.1/bk_installing_manually_book/content/rpm_chap3.html
        # The file is present inside HDP-2.0
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/mapred-queue-acls.xml"
          default: "#{__dirname}/../resources/core_hadoop/mapred-queue-acls.xml"
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
        next null, modified
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

    module.exports.push name: 'Hadoop MapRed # Tuning', callback: (ctx, next) ->
      {hadoop_conf_dir} = ctx.config.ryba
      {info, mapred_site} = memory ctx
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/mapred-site.xml"
        properties: mapred_site
        backup: true
        merge: true
      , next




