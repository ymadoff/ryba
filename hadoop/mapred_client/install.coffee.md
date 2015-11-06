
# MapReduce Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/hadoop/hdfs_client/install'
    module.exports.push 'ryba/hadoop/yarn_client/install'
    module.exports.push 'ryba/hadoop/hdfs_dn/wait'
    module.exports.push 'ryba/lib/hconfigure'
    module.exports.push 'ryba/lib/hdp_select'
    module.exports.push require '../../lib/hdfs_upload'
    module.exports.push require('./index').configure

## IPTables

| Service    | Port        | Proto | Parameter                                   |
|------------|-------------|-------|---------------------------------------------|
| mapreduce  | 59100-59200 | http  | yarn.app.mapreduce.am.job.client.port-range |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push header: 'MapReduce Client # IPTables', handler: ->
      {mapred} = @config.ryba
      jobclient = mapred.site['yarn.app.mapreduce.am.job.client.port-range']
      jobclient = jobclient.replace '-', ':'
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: jobclient, protocol: 'tcp', state: 'NEW', comment: "MapRed Client Range" }
        ]
        if: @config.iptables.action is 'start'

## Users & Groups

    module.exports.push header: 'MapReduce Client # Users & Groups', handler: ->
      {mapred, hadoop_group} = @config.ryba
      @group hadoop_group
      @user mapred.user

## Service

    module.exports.push header: 'MapReduce # Service', timeout: -1, handler: ->
      @service
        name: 'hadoop-mapreduce'
      @hdp_select
        name: 'hadoop-client'

    module.exports.push header: 'MapReduce Client # Configuration', handler: ->
      {mapred, hadoop_conf_dir} = @config.ryba
      @hconfigure
        destination: "#{hadoop_conf_dir}/mapred-site.xml"
        default: "#{__dirname}/../resources/mapred-site.xml"
        local_default: true
        properties: mapred.site
        merge: true
        backup: true
        uid: mapred.user.name
        gid: mapred.group.name

## HDFS Tarballs

Upload the MapReduce tarball inside the "/hdp/apps/$version/mapreduce"
HDFS directory. Note, the parent directories are created by the
"ryba/hadoop/hdfs_dn/layout" module.

    module.exports.push header: 'MapReduce Client # HDFS Tarballs', wait: 60*1000, timeout: -1, handler: ->
      @hdfs_upload
        source: '/usr/hdp/current/hadoop-client/mapreduce.tar.gz'
        target: '/hdp/apps/$version/mapreduce/mapreduce.tar.gz'
        lock: '/tmp/ryba-mapreduce.lock'

## Ulimit

Increase ulimit for the MapReduce user. The HDP package create the following
files:

```bash
cat /etc/security/limits.d/mapred.conf
mapred    - nofile 32768
mapred    - nproc  65536
```

Note, a user must re-login for those changes to be taken into account. See
the "ryba/hadoop/hdfs" module for additional information.

    module.exports.push header: 'MapReduce # Ulimit', handler: ->
      {user} = @config.ryba.mapred
      @write
        destination: '/etc/security/limits.d/#{user.name}.conf'
        write: [
          match: /^#{user.name}.+nofile.+$/mg
          replace: "#{user.name}  -    nofile   64000"
          append: true
        ,
          match: /^#{user.name}.+nproc.+$/mg
          replace: "#{user.name}  -    nproc    64000"
          append: true
        ]
        backup: true

## Dependencies

    mkcmd = require '../../lib/mkcmd'
