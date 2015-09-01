
# MapReduce JobHistoryServer Install

Install and configure the MapReduce Job History Server (JHS).

Run the command `./bin/ryba install -m ryba/hadoop/mapred_jhs` to install the
Job History Server.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdp_select'
    module.exports.push require('./index').configure

## IPTables

| Service          | Port  | Proto | Parameter                     |
|------------------|-------|-------|-------------------------------|
| jobhistory | 10020 | http  | mapreduce.jobhistory.address        | x
| jobhistory | 19888 | tcp   | mapreduce.jobhistory.webapp.address | x
| jobhistory | 19889 | tcp   | mapreduce.jobhistory.webapp.https.address | x
| jobhistory | 13562 | tcp   | mapreduce.shuffle.port              | x
| jobhistory | 10033 | tcp   | mapreduce.jobhistory.admin.address  |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'MapReduce JHS # IPTables', handler: (ctx, next) ->
      {mapred} = ctx.config.ryba
      jhs_shuffle_port = mapred.site['mapreduce.shuffle.port']
      jhs_port = mapred.site['mapreduce.jobhistory.address'].split(':')[1]
      jhs_webapp_port = mapred.site['mapreduce.jobhistory.webapp.address'].split(':')[1]
      jhs_webapp_https_port = mapred.site['mapreduce.jobhistory.webapp.https.address'].split(':')[1]
      jhs_admin_port = mapred.site['mapreduce.jobhistory.admin.address'].split(':')[1]
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS Server" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_webapp_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS WebApp" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_webapp_https_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS WebApp" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_shuffle_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS Shuffle" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_admin_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS Admin Server" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

## Service

Install the "hadoop-mapreduce-historyserver" service, symlink the rc.d startup
script inside "/etc/init.d" and activate it on startup.

    module.exports.push name: 'MapReduce JHS # Service', handler: (ctx, next) ->
      ctx
      .service
        name: 'hadoop-mapreduce-historyserver'
      .hdp_select
        name: 'hadoop-mapreduce-client' # Not checked
        name: 'hadoop-mapreduce-historyserver'
      .write
        source: "#{__dirname}/../resources/hadoop-mapreduce-historyserver"
        local_source: true
        destination: '/etc/init.d/hadoop-mapreduce-historyserver'
        mode: 0o0755
        unlink: true
      .execute
        cmd: "service hadoop-mapreduce-historyserver restart"
        if: -> @status -3
      .then next

## Environnement

Enrich the file "mapred-env.sh" present inside the Hadoop configuration
directory with the location of the directory storing the process pid.

Templated properties are "ryba.mapred.heapsize" and "ryba.mapred.pid_dir".

    module.exports.push name: 'MapReduce JHS # Environnement', handler: (ctx, next) ->
      {mapred, hadoop_conf_dir} = ctx.config.ryba
      @render
        destination: "#{hadoop_conf_dir}/mapred-env.sh"
        source: "#{__dirname}/../resources/mapred-env.sh"
        context: @config
        local_source: true
        backup: true
      .then next

    module.exports.push name: 'MapReduce JHS # Kerberos', handler: (ctx, next) ->
      {hadoop_conf_dir, mapred, yarn} = ctx.config.ryba
      ctx
      .hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        properties: yarn.site
        merge: true
        backup: true
      .hconfigure
        destination: "#{hadoop_conf_dir}/mapred-site.xml"
        properties: mapred.site
        merge: true
        backup: true
      .then next

## Layout

Create the log and pid directories.

    module.exports.push name: 'MapReduce Client # System Directories', timeout: -1, handler: (ctx, next) ->
      {mapred, hadoop_group} = ctx.config.ryba
      ctx
      .mkdir
        destination: "#{mapred.log_dir}/#{mapred.user.name}"
        uid: mapred.user.name
        gid: hadoop_group.name
        mode: 0o0755
      .mkdir
        destination: "#{mapred.pid_dir}"
        uid: mapred.user.name
        gid: hadoop_group.name
        mode: 0o0755
      .mkdir
        destination: mapred.site['mapreduce.jobhistory.recovery.store.leveldb.path']
        uid: mapred.user.name
        gid: hadoop_group.name
        mode: 0o0750
        parent: true
        if: mapred.site['mapreduce.jobhistory.recovery.store.class'] is 'org.apache.hadoop.mapreduce.v2.hs.HistoryServerLeveldbStateStoreService'
      .then next

## Kerberos

Create the Kerberos service principal by default in the form of
"jhs/{host}@{realm}" and place its keytab inside
"/etc/security/keytabs/jhs.service.keytab" with ownerships set to
"mapred:hadoop" and permissions set to "0600".

    module.exports.push name: 'MapReduce JHS # Kerberos', handler: (ctx, next) ->
      {mapred, hadoop_group, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: "jhs/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/jhs.service.keytab"
        uid: mapred.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
        mode: 0o0600
      .then next

## HDFS Layout

Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)

    module.exports.push 'ryba/hadoop/hdfs_nn/wait'
    module.exports.push 'ryba/hadoop/hdfs_client/install'
    module.exports.push name: 'MapReduce JHS # HDFS Layout', timeout: -1, handler: (ctx, next) ->
      {yarn, mapred} = ctx.config.ryba
      ctx.execute
        cmd: mkcmd.hdfs ctx, """
        if ! hdfs dfs -test -d #{mapred.site['yarn.app.mapreduce.am.staging-dir']}/history; then
          hdfs dfs -mkdir -p #{mapred.site['yarn.app.mapreduce.am.staging-dir']}/history
          hdfs dfs -chmod 0755 #{mapred.site['yarn.app.mapreduce.am.staging-dir']}/history
          hdfs dfs -chown #{mapred.user.name} #{mapred.site['yarn.app.mapreduce.am.staging-dir']}/history
          modified=1
        fi
        if ! hdfs dfs -test -d /app-logs; then
          hdfs dfs -mkdir -p /app-logs
          hdfs dfs -chmod 1777 /app-logs
          hdfs dfs -chown #{yarn.user.name} /app-logs
          modified=1
        fi
        if [ $modified != "1" ]; then exit 2; fi
        """
        code_skipped: 2
      .then next

## Dependencies

    mkcmd = require '../../lib/mkcmd'

[keys]: https://github.com/apache/hadoop-common/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/DFSConfigKeys.java
