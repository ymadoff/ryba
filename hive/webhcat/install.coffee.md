
# WebHCat

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs' # Install SPNEGO keytab
    module.exports.push 'ryba/hive/client'
    module.exports.push 'ryba/tools/pig'
    module.exports.push 'ryba/tools/sqoop'
    module.exports.push require('./index').configure
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdp_service'

## IPTables

| Service | Port  | Proto | Info                |
|---------|-------|-------|---------------------|
| webhcat | 50111 | http  | WebHCat HTTP server |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'WebHCat # IPTables', handler: (ctx, next) ->
      {webhcat} = ctx.config.ryba
      port = webhcat.site['templeton.port']
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'tcp', state: 'NEW', comment: "WebHCat HTTP Server" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

    # module.exports.push name: 'WebHCat # Install', timeout: -1, handler: (ctx, next) ->
    #   ctx.service [
    #     name: 'hive-hcatalog'
    #   ,
    #     name: 'hive-webhcat'
    #   ,
    #     name: 'webhcat-tar-hive'
    #   ,
    #     name: 'webhcat-tar-pig'
    #   ], next

## Startup

Install the "hadoop-yarn-resourcemanager" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

    module.exports.push name: 'WebHCat # Service', handler: (ctx, next) ->
      {webhcat} = ctx.config.ryba
      ctx.hdp_service
        name: 'hive-webhcat-server'
        version_name: 'hive-webhcat'
        write: [
          match: /^\. \/etc\/default\/hive-webhcat-server .*$/m
          replace: '. /etc/default/hive-webhcat-server # RYBA FIX rc.d, DONT OVERWRITE'
          append: ". /lib/lsb/init-functions"
        # ,
        #   # HDP default is "/etc/hbase/conf"
        #   match: /^CONF_DIR=.*$/m
        #   replace: "CONF_DIR=\"${HBASE_CONF_DIR}\" # RYBA HONORS /etc/default, DONT OVEWRITE"
        ,
          # HDP default is "/usr/lib/hbase/bin/hbase-daemon.sh"
          match: /^EXEC_PATH=.*$/m
          replace: "EXEC_PATH=\"${HCAT_HOME}/sbin/webhcat_server.sh\" # RYBA HONORS /etc/default, DONT OVEWRITE"
        ,
          # HDP default is "/var/lib/hive-hcatalog/hcat.pid"
          match: /^PIDFILE=.*$/m
          replace: "PIDFILE=\"${WEBHCAT_PID_DIR}/webhcat.pid\" # RYBA HONORS /etc/default, DONT OVEWRITE"
        ]
        etc_default:
          'hadoop': true
          'hive-webhcat-server':
            write: [
              match: /^export WEBHCAT_PID_DIR=.*$/m # HDP default is "/var/lib/hive-hcatalog"
              replace: "export WEBHCAT_PID_DIR=#{webhcat.pid_dir} # RYBA FIX"
            ,
              match: /^export HCAT_HOME=.*$/m # HDP default is "/usr/lib/hive-hcatalog"
              replace: "export HCAT_HOME=/usr/hdp/current/hive-webhcat # RYBA FIX"
            ,
              match: /^export HIVE_HOME=.*$/m # HDP default is "/usr/lib/hive"
              replace: "export HIVE_HOME=/usr/hdp/current/hive-metastore # RYBA FIX"
            ]
      , next

    # module.exports.push name: 'WebHCat # Startup', handler: (ctx, next) ->
    #   {webhcat} = ctx.config.ryba
    #   modified = false
    #   do_install = ->
    #     ctx.service
    #       name: 'hive-webhcat-server'
    #       startup: true
    #     , (err, serviced) ->
    #       return next err if err
    #       modified = true if serviced
    #       do_write()
    #   do_write = ->
    #     ctx.write [
    #       destination: '/etc/init.d/hive-webhcat-server'
    #       match: /^PIDFILE=".*"$/m
    #       replace: "PIDFILE=\"#{webhcat.pid_dir}/webhcat.pid\""
    #     ,
    #       destination: '/etc/init.d/hive-webhcat-server'
    #       match: /^.*# Ryba: clean pidfile if pid not running$/m
    #       replace: """
    #       if pid=`cat $PIDFILE`; then if ! ps -e -o pid | grep -v grep | grep -w $pid; then rm $PIDFILE; fi; fi; \# Ryba: clean pidfile if pid not running
    #       """
    #       append: /^PIDFILE=.*$/m
    #     ], (err, written) ->
    #       return next err if err
    #       modified = true if written
    #       do_end()
    #   do_end = ->
    #     next null, modified
    #   do_install()

    module.exports.push name: 'WebHCat # Directories', handler: (ctx, next) ->
      {webhcat, hive, hadoop_group} = ctx.config.ryba
      modified = false
      do_log = ->
        ctx.mkdir
          destination: webhcat.log_dir
          uid: hive.user.name
          gid: hadoop_group.name
          mode: 0o755
        , (err, created) ->
          return next err if err
          modified = true if created
          do_pid()
      do_pid = ->
        ctx.mkdir
          destination: webhcat.pid_dir
          uid: hive.user.name
          gid: hadoop_group.name
          mode: 0o755
        , (err, created) ->
          return next err if err
          modified = true if created
          do_end()
      do_end = ->
        next null, modified
      do_log()

    module.exports.push name: 'WebHCat # Configuration', handler: (ctx, next) ->
      {webhcat, hive, hadoop_group} = ctx.config.ryba
      ctx
      .hconfigure
        destination: "#{webhcat.conf_dir}/webhcat-site.xml"
        default: "#{__dirname}/../../resources/hive-webhcat/webhcat-site.xml"
        local_default: true
        properties: webhcat.site
        uid: hive.user.name
        gid: hadoop_group.name
        mode: 0o0755
        merge: true
      .then next

    module.exports.push name: 'WebHCat # Env', handler: (ctx, next) ->
      {webhcat, hive, hadoop_group} = ctx.config.ryba
      ctx.log 'Write webhcat-env.sh'
      ctx.upload
        source: "#{__dirname}/../../resources/hive-webhcat/webhcat-env.sh"
        destination: "#{webhcat.conf_dir}/webhcat-env.sh"
        uid: hive.user.name
        gid: hadoop_group.name
        mode: 0o0755
      , next

## HDFS Tarballs

Upload the Pig, Hive and Sqoop tarballs inside the "/hdp/apps/$version"
HDFS directory. Note, the parent directories are created by the
"ryba/hadoop/hdfs_dn/layout" module.

    module.exports.push name: 'WebHCat # HDFS Tarballs', timeout: -1, handler: (ctx, next) ->
      {hdfs, hadoop_group} = ctx.config.ryba
      # Group name on "/apps/tez" is suggested as "users", switch to hadoop
      modified = false
      each ['pig', 'hive', 'sqoop']
      .run (lib, next) ->
        ctx.execute
          cmd: mkcmd.hdfs ctx, """
          version=`readlink /usr/hdp/current/#{lib}-client | sed 's/.*\\/\\(.*\\)\\/#{lib}/\\1/'`
          hdfs dfs -mkdir -p /hdp/apps/$version/#{lib}
          hdfs dfs -copyFromLocal /usr/hdp/current/#{lib}-client/#{lib}.tar.gz /hdp/apps/$version/#{lib}
          hdfs dfs -chmod -R 555 /hdp/apps/$version/#{lib}
          hdfs dfs -chmod -R 444 /hdp/apps/$version/#{lib}/#{lib}.tar.gz
          hdfs dfs -ls /hdp/apps/$version/#{lib} | grep #{lib}.tar.gz
          """
          trap_on_error: true
          not_if_exec: mkcmd.hdfs ctx, "version=`readlink /usr/hdp/current/#{lib}-client | sed 's/.*\\/\\(.*\\)\\/#{lib}/\\1/'` && hdfs dfs -test -d /hdp/apps/$version/#{lib}"
        , next
      .then (err) -> next err, modified

    # module.exports.push name: 'WebHCat # HDFS', handler: (ctx, next) ->
    #   {hive} = ctx.config.ryba
    #   modified = false
    #   ctx.execute [
    #     cmd: mkcmd.hdfs ctx, """
    #     if hdfs dfs -test -d /user/#{hive.user.name}; then exit 1; fi
    #     hdfs dfs -mkdir -p /user/#{hive.user.name}
    #     hdfs dfs -chown #{hive.user.name}:#{hive.group.name} /user/#{hive.user.name}
    #     """
    #     code_skipped: 1
    #   ,
    #     cmd: mkcmd.hdfs ctx, """
    #     if hdfs dfs -test -d /apps/webhcat; then exit 1; fi
    #     hdfs dfs -mkdir -p /apps/webhcat
    #     """
    #     code_skipped: 1
    #   ], (err, created, stdout) ->
    #     return next err if err
    #     modified = true if created
    #     each([
    #       '/usr/share/HDP-webhcat/pig.tar.gz'
    #       '/usr/share/HDP-webhcat/hive.tar.gz'
    #       '/usr/lib/hadoop-mapreduce/hadoop-streaming*.jar'
    #     ])
    #     .on 'item', (item, next) ->
    #       ctx.execute
    #         cmd: mkcmd.hdfs ctx, "hdfs dfs -copyFromLocal #{item} /apps/webhcat/"
    #         code_skipped: 1
    #       , (err, copied) ->
    #         return next err if err
    #         modified = true if copied
    #         next()
    #     .on 'both', (err) ->
    #       return next err if err
    #       ctx.execute
    #         cmd: mkcmd.hdfs ctx, """
    #         hdfs dfs -chown -R #{hive.user.name}:users /apps/webhcat
    #         hdfs dfs -chmod -R 755 /apps/webhcat
    #         """
    #       , (err, executed, stdout) ->
    #         next err, modified

    module.exports.push name: 'WebHCat # Fix HDFS tmp', handler: (ctx, next) ->
      # Avoid HTTP response
      # Permission denied: user=ryba, access=EXECUTE, inode=\"/tmp/hadoop-hcat\":HTTP:hadoop:drwxr-x---
      {hive, hadoop_group} = ctx.config.ryba
      modified = false
      ctx.execute [
        cmd: mkcmd.hdfs ctx, """
        if hdfs dfs -test -d /tmp/hadoop-hcat; then exit 2; fi
        hdfs dfs -mkdir -p /tmp/hadoop-hcat
        hdfs dfs -chown HTTP:#{hadoop_group.name} /tmp/hadoop-hcat
        hdfs dfs -chmod -R 1777 /tmp/hadoop-hcat
        """
        code_skipped: 2
      ], next

    module.exports.push name: 'WebHCat # SPNEGO', handler: (ctx, next) ->
      {webhcat, hive, hadoop_group} = ctx.config.ryba
      ctx.copy
        source: '/etc/security/keytabs/spnego.service.keytab'
        destination: webhcat.site['templeton.kerberos.keytab']
        uid: hive.user.name
        gid: hadoop_group.name
        mode: 0o0660
      , next

## Dependencies

    each = require 'each'
    lifecycle = require '../../lib/lifecycle'
    mkcmd = require '../../lib/mkcmd'

## TODO: Check Hive

hdfs dfs -mkdir -p front1-webhcat/mytable
echo -e 'a,1\nb,2\nc,3' | hdfs dfs -put - front1-webhcat/mytable/data
hive
  create database testhcat location '/user/ryba/front1-webhcat';
  create table testhcat.mytable(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
curl --negotiate -u : -d execute="use+testhcat;select+*+from+mytable;" -d statusdir="testhcat1" http://front1.hadoop:50111/templeton/v1/hive
hdfs dfs -cat testhcat1/stderr
hdfs dfs -cat testhcat1/stdout
