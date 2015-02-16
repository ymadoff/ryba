
# Hadoop MapRed Install

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

    module.exports.push name: 'MapRed Client # IPTables', handler: (ctx, next) ->
      {mapred} = ctx.config.ryba
      jobclient = mapred.site['yarn.app.mapreduce.am.job.client.port-range']
      jobclient = jobclient.replace '-', ':'
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: jobclient, protocol: 'tcp', state: 'NEW', comment: "MapRed Client Range" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

    module.exports.push name: 'MapRed # Install Common', timeout: -1, handler: (ctx, next) ->
      ctx.service [
        name: 'hadoop'
      ,
        name: 'hadoop-mapreduce'
      ,
        name: 'hadoop-client'
      ], next

http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-9.html
http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode

    module.exports.push name: 'MapRed Client # Users & Groups', handler: (ctx, next) ->
      {mapred, hadoop_group} = ctx.config.ryba
      ctx.execute
        cmd: "useradd #{mapred.user.name} -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Hadoop MapReduce service\""
        code: 0
        code_skipped: 9
      , next

    module.exports.push name: 'MapRed Client # System Directories', timeout: -1, handler: (ctx, next) ->
      {mapred, hadoop_group} = ctx.config.ryba
      modified = false
      do_log = ->
        ctx.log "Create hdfs and mapred log: #{mapred.log_dir}"
        ctx.mkdir
          destination: "#{mapred.log_dir}/#{mapred.user.name}"
          uid: mapred.user.name
          gid: hadoop_group.name
          mode: 0o0755
        , (err, created) ->
          return next err if err
          modified = true if created
          do_pid()
      do_pid = ->
        ctx.log "Create hdfs and mapred pid: #{mapred.pid_dir}"
        ctx.mkdir
          destination: "#{mapred.pid_dir}/#{mapred.user.name}"
          uid: mapred.user.name
          gid: hadoop_group.name
          mode: 0o0755
        , (err, created) ->
          return next err if err
          modified = true if created
          do_end()
      do_end = ->
        next null, modified
      do_log()

    module.exports.push name: 'MapRed Client # Configuration', handler: (ctx, next) ->
      {mapred, hadoop_conf_dir} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/mapred-site.xml"
        default: "#{__dirname}/../resources/core_hadoop/mapred-site.xml"
        local_default: true
        properties: mapred.site
        merge: true
        backup: true
        uid: mapred.user.name
        gid: mapred.group.name
      , next




