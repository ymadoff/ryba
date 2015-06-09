
# MapReduce JobHistoryServer Install

Install and configure the MapReduce Job History Server (JHS).

Run the command `./bin/ryba install -m ryba/hadoop/mapred_jhs` to install the
Job History Server.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push require('./index').configure
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdp_service'

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
      ctx.hdp_service
        name: 'hadoop-mapreduce-historyserver'
        write: [
          match: /^\. \$CONF_DIR\/mapred-env\.sh .*$/m
          replace: '. $CONF_DIR/mapred-env.sh # RYBA FIX pid dir'
          append: '. $CONF_DIR/hadoop-env.sh'
        ,
          match:  /^HADOOP_PID_DIR=".*" # RYBA .*$/m
          replace: 'HADOOP_PID_DIR="${HADOOP_MAPRED_PID_DIR:-$HADOOP_PID_DIR}" # RYBA FIX pid dir'
          before: /^PIDFILE=".*"$/m
        ]
      .then next

## Environnement

Enrich the file "mapred-env.sh" present inside the Hadoop configuration
directory with the location of the directory storing the process pid.

    module.exports.push name: 'MapReduce JHS # Environnement', handler: (ctx, next) ->
      {mapred, hadoop_conf_dir} = ctx.config.ryba
      ctx.write
        destination: "#{hadoop_conf_dir}/mapred-env.sh"
        source: "#{__dirname}/../../resources/core_hadoop/mapred-env.sh"
        local_source: true
        backup: true
        write: [
          match: /^export HADOOP_MAPRED_PID_DIR=.*$/m
          replace: "export HADOOP_MAPRED_PID_DIR=\"#{mapred.pid_dir}\" # RYBA CONF \"ryba.mapred.pid_dir\", DONT OVEWRITE"
          before: /^#export HADOOP_MAPRED_LOG_DIR.*/m
        ]
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
        destination: "#{mapred.pid_dir}/#{mapred.user.name}"
        uid: mapred.user.name
        gid: hadoop_group.name
        mode: 0o0755
      .then next

## HDFS Layout

Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)

    module.exports.push name: 'MapReduce JHS # HDFS Layout', timeout: -1, handler: (ctx, next) ->
      {hadoop_group, yarn, mapred} = ctx.config.ryba
      ctx.execute
        cmd: mkcmd.hdfs ctx, """
        if ! hdfs dfs -test -d /mr-history; then
          hdfs dfs -mkdir -p /mr-history
          hdfs dfs -chmod 0751 /mr-history
          hdfs dfs -chown #{mapred.user.name}:#{hadoop_group.name} /mr-history
          modified=1
        fi
        if ! hdfs dfs -test -d /mr-history/tmp; then
          hdfs dfs -mkdir -p /mr-history/tmp
          hdfs dfs -chmod 1777 /mr-history/tmp
          hdfs dfs -chown #{mapred.user.name}:#{hadoop_group.name} /mr-history/tmp
          modified=1
        fi
        if ! hdfs dfs -test -d /mr-history/done; then
          hdfs dfs -mkdir -p /mr-history/done
          hdfs dfs -chmod 1777 /mr-history/done
          hdfs dfs -chown #{mapred.user.name}:#{hadoop_group.name} /mr-history/done
          modified=1
        fi
        if ! hdfs dfs -test -d /app-logs; then
          hdfs dfs -mkdir -p /app-logs
          hdfs dfs -chmod 1777 /app-logs
          hdfs dfs -chown #{yarn.user.name}:#{hadoop_group.name} /app-logs
          modified=1
        fi
        if [ $modified != "1" ]; then exit 2; fi
        """
        code_skipped: 2
      .then next

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
      .then next

## Dependencies

    mkcmd = require '../../lib/mkcmd'

[keys]: https://github.com/apache/hadoop-common/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/DFSConfigKeys.java
