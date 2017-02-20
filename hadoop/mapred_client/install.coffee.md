
# MapReduce Install

    module.exports = header: 'MapReduce Client Install', handler: ->
      {iptables} = @config
      {hadoop_group, hadoop_conf_dir, mapred} = @config.ryba

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register 'hdfs_upload', 'ryba/lib/hdfs_upload'

## IPTables

| Service    | Port        | Proto | Parameter                                   |
|------------|-------------|-------|---------------------------------------------|
| mapreduce  | 59100-59200 | http  | yarn.app.mapreduce.am.job.client.port-range |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      jobclient = mapred.site['yarn.app.mapreduce.am.job.client.port-range']
      jobclient = jobclient.replace '-', ':'
      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: jobclient, protocol: 'tcp', state: 'NEW', comment: "MapRed Client Range" }
        ]
        if: iptables.action is 'start'

## Users & Groups

      @group header: 'Group', hadoop_group
      @user header: 'User', mapred.user

## Service

      @call header: 'Packages', timeout: -1, handler: ->
        @service
          name: 'hadoop-mapreduce'
        @hdp_select
          name: 'hadoop-client'

      @hconfigure
        header: 'Configuration'
        target: "#{hadoop_conf_dir}/mapred-site.xml"
        source: "#{__dirname}/../resources/mapred-site.xml"
        local_source: true
        properties: mapred.site
        backup: true
        uid: mapred.user.name
        gid: mapred.group.name

## HDFS Tarballs

Upload the MapReduce tarball inside the "/hdp/apps/$version/mapreduce"
HDFS directory. Note, the parent directories are created by the
"ryba/hadoop/hdfs_dn/layout" module.

      @hdfs_upload
        header: 'HDFS Tarballs'
        wait: 60*1000
        timeout: -1
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

      @system.limits
        header: 'Ulimit'
        user: mapred.user.name
      , mapred.user.limits

## Dependencies

    mkcmd = require '../../lib/mkcmd'
