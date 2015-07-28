
# MapReduce Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/hadoop/hdfs_client'
    module.exports.push 'ryba/hadoop/yarn_client'
    module.exports.push 'ryba/hadoop/hdfs_dn/wait'
    module.exports.push require '../../lib/hconfigure'
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

    module.exports.push name: 'MapReduce # Install Common', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'hadoop-mapreduce'
      .then next

http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-9.html
http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode

    module.exports.push name: 'MapReduce Client # Users & Groups', handler: (ctx, next) ->
      {mapred, hadoop_group} = ctx.config.ryba
      ctx.execute
        cmd: "useradd #{mapred.user.name} -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Hadoop MapReduce service\""
        code: 0
        code_skipped: 9
      .then next

    module.exports.push name: 'MapReduce Client # Configuration', handler: (ctx, next) ->
      {mapred, hadoop_conf_dir} = ctx.config.ryba
      ctx
      .hconfigure
        destination: "#{hadoop_conf_dir}/mapred-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/mapred-site.xml"
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
      {hdfs, hadoop_group} = ctx.config.ryba
      ctx.execute
        cmd: mkcmd.hdfs ctx, """
        version=`readlink /usr/hdp/current/hadoop-mapreduce-client | sed 's/.*\\/\\(.*\\)\\/hadoop-mapreduce/\\1/'`
        if hdfs dfs -mkdir /tmp/ryba-mapreduce.lock; then
          echo "Lock created"
        else
          echo 'lock exist, check if valid'
          timeout=240 # 4 minutes
          now=`date '+%s'`
          crdate=$(echo `hdfs dfs -ls /tmp/ryba-mapreduce.lock | grep -Po '\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}'` | xargs -0 date '+%s' -d)
          #expire=$(($crdate - `date '+%s'` + $timeout))
          #if [ $expire -ge $timeout ]; then
          if [ $(($now - $crdate)) -le $timeout ]; then
            sleep_time=$((240 - $crdate + $now + 5))
            echo crdate $crdate
            echo now $now
            echo sleep_time $sleep_time
            echo "Lock is active, wait for ${sleep_time}s until expiration"
            sleep $sleep_time
            if hdfs dfs -test -d /tmp/ryba-mapreduce.lock; then
              echo "Lock still present after waiting"
              exit 1
            fi
            if hdfs dfs -test -f /hdp/apps/$version/mapreduce/mapreduce.tar.gz; then
              echo "File uploaded in parallel by somebody else"
              exit 0
            fi
            echo "Lock released, attemp to upload file"
          else
            echo "Lock has expired $(($now - $crdate + $timeout))s ago, pursue uploading"
          fi
        fi
        echo "Upload file in /hdp/apps/$version/mapreduce"
        hdfs dfs -mkdir -p /hdp/apps/$version/mapreduce
        hdfs dfs -chmod -R 555 /hdp/apps/$version/mapreduce
        hdfs dfs -chmod -R 555 /hdp/apps/$version/mapreduce
        hdfs dfs -copyFromLocal /usr/hdp/current/hadoop-client/mapreduce.tar.gz /hdp/apps/$version/mapreduce
        hdfs dfs -chmod -R 444 /hdp/apps/$version/mapreduce/mapreduce.tar.gz
        hdfs dfs -test -f /hdp/apps/$version/mapreduce/mapreduce.tar.gz
        hdfs dfs -rm -r /tmp/ryba-mapreduce.lock
        """
        trap_on_error: true
        not_if_exec: mkcmd.hdfs ctx, """
        version=`readlink /usr/hdp/current/hadoop-mapreduce-client | sed 's/.*\\/\\(.*\\)\\/hadoop-mapreduce/\\1/'`
        hdfs dfs -test -f /hdp/apps/$version/mapreduce/mapreduce.tar.gz
        """
      .then next

## Dependencies

    mkcmd = require '../../lib/mkcmd'
