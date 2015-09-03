
# MapReduce Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/hadoop/hdfs_client/install'
    module.exports.push 'ryba/hadoop/yarn_client/install'
    module.exports.push 'ryba/hadoop/hdfs_dn/wait'
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdp_select'
    module.exports.push require '../../lib/hdfs_upload'
    module.exports.push require('./index').configure

## IPTables

| Service    | Port        | Proto | Parameter                                   |
|------------|-------------|-------|---------------------------------------------|
| mapreduce  | 59100-59200 | http  | yarn.app.mapreduce.am.job.client.port-range |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'MapReduce Client # IPTables', handler: (ctx, next) ->
      {mapred} = ctx.config.ryba
      jobclient = mapred.site['yarn.app.mapreduce.am.job.client.port-range']
      jobclient = jobclient.replace '-', ':'
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: jobclient, protocol: 'tcp', state: 'NEW', comment: "MapRed Client Range" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

## Users & Groups

    module.exports.push name: 'MapReduce Client # Users & Groups', handler: (ctx, next) ->
      {mapred, hadoop_group} = ctx.config.ryba
      ctx
      .group hadoop_group
      .user mapred.user
      .then next

## Service

    module.exports.push name: 'MapReduce # Service', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'hadoop-mapreduce'
      .hdp_select
        name: 'hadoop-client'
      .then next

    module.exports.push name: 'MapReduce Client # Configuration', handler: (ctx, next) ->
      {mapred, hadoop_conf_dir} = ctx.config.ryba
      ctx
      .hconfigure
        destination: "#{hadoop_conf_dir}/mapred-site.xml"
        default: "#{__dirname}/../resources/mapred-site.xml"
        local_default: true
        properties: mapred.site
        merge: true
        backup: true
        uid: mapred.user.name
        gid: mapred.group.name
      .then next

## HDFS Tarballs

Upload the MapReduce tarball inside the "/hdp/apps/$version/mapreduce"
HDFS directory. Note, the parent directories are created by the
"ryba/hadoop/hdfs_dn/layout" module.

    module.exports.push name: 'MapReduce Client # HDFS Tarballs', wait: 60*1000, timeout: -1, handler: (ctx, next) ->
      ctx.hdfs_upload
        source: '/usr/hdp/current/hadoop-client/mapreduce.tar.gz'
        target: '/hdp/apps/$version/mapreduce/mapreduce.tar.gz'
        lock: '/tmp/ryba-mapreduce.lock'
      .then next

## Dependencies

    mkcmd = require '../../lib/mkcmd'
