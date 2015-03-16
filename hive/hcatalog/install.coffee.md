
# Hive HCatalog Install

TODO: Implement lock for Hive Server2
http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_18_5.html

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/krb5_client'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/mysql_client' # Install the mysql connector
    module.exports.push 'ryba/hadoop/mapred_client'
    module.exports.push 'ryba/tez'
    module.exports.push 'ryba/hive/client/install' # Install the Hive and HCatalog service
    module.exports.push 'ryba/hadoop/hdfs_dn_wait'
    module.exports.push 'ryba/hbase/client'
    module.exports.push require('./index').configure
    module.exports.push require '../../lib/hdp_service'

## IPTables

| Service        | Port  | Proto | Parameter            |
|----------------|-------|-------|----------------------|
| Hive Metastore | 9083  | http  | hive.metastore.uris  |
| Hive Web UI    | 9999  | http  | hive.hwi.listen.port |


IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'Hive & HCat Server # IPTables', handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 9083, protocol: 'tcp', state: 'NEW', comment: "Hive Metastore" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 9999, protocol: 'tcp', state: 'NEW', comment: "Hive Web UI" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Startup

Install the "hive-hcatalog-server" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

Note, the server is not activated on startup but they endup as zombies if HDFS
isnt yet started.

    module.exports.push name: 'Hive & HCat Server # Startup', handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      ctx.hdp_service
        name: 'hive-hcatalog-server'
        version_name: 'hive-metastore'
        startup: false
        write: [
          match: /^\. \/etc\/default\/hive-hcatalog-server .*$/m
          replace: '. /etc/default/hive-hcatalog-server # RYBA FIX rc.d, DONT OVERWRITE'
          append: ". /lib/lsb/init-functions"
        ,
          # HDP default is "/etc/hive-hcatalog/conf"
          match: /^CONF_DIR=.*$/m
          replace: "CONF_DIR=\"${HIVE_CONF_DIR}\" # RYBA HONORS /etc/default, DONT OVEWRITE"
        ,
          # HDP default is "/usr/lib/hive-hcatalog/sbin/hcat_server.sh"
          match: /^EXEC_PATH=.*$/m
          replace: "EXEC_PATH=\"${HCAT_HOME}/sbin/hcat_server.sh\" # RYBA HONORS /etc/default, DONT OVEWRITE"
        ,
          # HDP default is "/var/lib/hive-hcatalog/hcat.pid"
          match: /^PIDFILE=.*$/m
          replace: "PIDFILE=\"${HCAT_PID_DIR}/hcat.pid\" # RYBA HONORS /etc/default, DONT OVEWRITE"
        ]
        etc_default:
          'hive-hcatalog-server': 
            write: [
              match: /^export HCAT_PID_DIR=.*$/m # HDP default is "/var/lib/hive-hcatalog"
              replace: "export HCAT_PID_DIR=#{hive.hcatalog_pid_dir} # RYBA FIX"
            ,
              match: /^export HCAT_HOME=.*$/m # HDP default is "/usr/lib/hive-hcatalog"
              replace: "export HCAT_HOME=/usr/hdp/current/hive-webhcat # RYBA FIX"
            ,
              match: /^export HIVE_HOME=.*$/m # HDP default is "/usr/lib/hive"
              replace: "export HIVE_HOME=/usr/hdp/current/hive-metastore # RYBA FIX"
            ]
      , next

    module.exports.push name: 'Hive & HCat Server # Database', handler: (ctx, next) ->
      {hive, db_admin} = ctx.config.ryba
      username = hive.site['javax.jdo.option.ConnectionUserName']
      password = hive.site['javax.jdo.option.ConnectionPassword']
      {engine, host, db} = parse_jdbc hive.site['javax.jdo.option.ConnectionURL']
      engines = 
        mysql: ->
          do_exists = ->
            cmd = "#{db_admin.path} -u#{username} -p#{password} -h#{db_admin.host} -P#{db_admin.port}"
            ctx.execute
              cmd: "if ! #{cmd} -e \"USE #{db};\"; then exit 3; fi"
              code_skipped: 3
            , (err, exists) ->
              return next err if err
              if exists then do_upgrade() else do_db()
          do_db = ->
            cmd = "#{db_admin.path} -u#{db_admin.username} -p#{db_admin.password} -h#{db_admin.host} -P#{db_admin.port}"
            ctx.execute
              cmd: """
              #{cmd} -e "
              create database if not exists #{db};
              grant all privileges on #{db}.* to '#{username}'@'localhost' identified by '#{password}';
              grant all privileges on #{db}.* to '#{username}'@'%' identified by '#{password}';
              flush privileges;
              "
              """
            , (err) ->
              return next err if err
              do_create()
          do_create = ->
            cmd = "#{db_admin.path} -u#{username} -p#{password} -h#{db_admin.host} -P#{db_admin.port}"
            create_version = 'ls /usr/hdp/current/hive-metastore/lib | grep hive-common- | sed \'s/^hive-common-\\([0-9]\\+.[0-9]\\+.[0-9]\\+\\).*\\.jar$/\\1/g\''
            ctx.execute
              cmd: """
              create_version=`#{create_version}`
              create=/usr/hdp/current/hive-metastore/scripts/metastore/upgrade/mysql/hive-schema-${create_version}.mysql.sql
              create_major_version=`echo $create_version | sed \'s/^\\([0-9]\\+\\).\\([0-9]\\+\\).\\([0-9]\\+\\)$/\\1.\\2.0/g\'`
              create_major=/usr/hdp/current/hive-metastore/scripts/metastore/upgrade/mysql/hive-schema-${create_major_version}.mysql.sql
              if ! test -f $create && ! test -f $create_major; then exit 1; fi
              # Create schema
              if test -f $create; then
                #{cmd} #{db} < $create;
              elif test -f $create_major; then
                #{cmd} #{db} < $create_major;
              fi
              # Import transaction schema (now created with 0.13.1)
              #trnx=/usr/hdp/current/hive-metastore/scripts/metastore/upgrade/mysql/hive-txn-schema-${create_version}.mysql.sql
              #trnx_major=/usr/hdp/current/hive-metastore/scripts/metastore/upgrade/mysql/hive-txn-schema-${create_major_version}.mysql.sql
              #if test -f $trnx; then #{cmd} #{db} < $trnx;
              #elif test -f $trnx_major; then #{cmd} #{db} < $trnx_major; fi
              """
            , next
          do_upgrade = ->
            cmd = "#{db_admin.path} -u#{username} -p#{password} -h#{db_admin.host} -P#{db_admin.port}"
            current_version = "#{db_admin.path} -u#{username} -p#{password} -h#{db_admin.host} -P#{db_admin.port} -e 'select SCHEMA_VERSION from hive.VERSION' --skip-column-names"
            target_version = 'ls /usr/hdp/current/hive-metastore/lib | grep hive-common- | sed \'s/^hive-common-\\([0-9]\\+.[0-9]\\+.[0-9]\\+\\).*\\.jar$/\\1/g\''
            ctx.execute
              cmd: """
              current=`#{current_version}`
              target=`#{target_version}`
              if [ $current == $target ]; then exit 3; fi
              # Upgrade schema
              upgrade=/usr/hdp/current/hive-metastore/scripts/metastore/upgrade/mysql/upgrade-${current}-to-${target}.mysql.sql
              if ! test -f $upgrade; then
                current_major=`echo $target | sed \'s/^\\([0-9]\\+\\).\\([0-9]\\+\\).\\([0-9]\\+\\)$/\\1.\\2/g\'`
                target_major=`echo $target | sed \'s/^\\([0-9]\\+\\).\\([0-9]\\+\\).\\([0-9]\\+\\)$/\\1.\\2/g\'`
                if [ $current_major == $target_major ]; then exit 0; fi
                exit 1;
              fi
              cd `dirname $upgrade`
              #{cmd} #{db} < $upgrade
              # Import transaction schema (now created with 0.13.1)
              #trnx=/usr/hdp/current/hive-metastore/scripts/metastore/upgrade/mysql/hive-txn-schema-${target}.mysql.sql
              #if test -f $trnx; then #{cmd} #{db} < $trnx; fi
              """
              code_skipped: 3
            , next
          do_exists()
      return next new Error 'Database engine not supported' unless engines[engine]
      engines[engine]()

    module.exports.push name: 'Hive & HCat Server # Configure', handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hive.conf_dir}/hive-site.xml"
        default: "#{__dirname}/../../resources/hive/hive-site.xml"
        local_default: true
        properties: hive.site
        merge: true
      , (err, configured) ->
        return next err if err
        ctx.execute
          cmd: """
          chown -R #{hive.user.name}:#{hive.group.name} #{hive.conf_dir}/
          chmod -R 755 #{hive.conf_dir}
          """
        , (err) ->
          next err, configured

## Env

Enrich the "hive-env.sh" file with the value of the configuration property
"ryba.hive.hcatalog_opts". Internally, the environmental variable
"HADOOP_CLIENT_OPTS" is enriched and only apply to the Hive HCatalog server.

Using this functionnality, a user may for example raise the heap size of Hive
HCatalog to 4Gb by setting a value equal to "-Xmx4096m".

Note, the startup script found in "hive-hcatalog/bin/hcat_server.sh" references
the Hive Metastore service and execute "./bin/hive --service metastore"

    module.exports.push name: 'Hive & HCat Server # Env', handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      ctx.write
        destination: "#{hive.conf_dir}/hive-env.sh"
        replace: """
        if [ "$SERVICE" = "metastore" ]; then
          # export HADOOP_CLIENT_OPTS="-Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=130.98.196.54 -Dcom.sun.management.jmxremote.rmi.port=9526 -Dcom.sun.management.jmxremote.port=9526 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false  $HADOOP_CLIENT_OPTS"
          export HADOOP_CLIENT_OPTS="#{hive.hcatalog_opts} $HADOOP_CLIENT_OPTS"
        fi
        """
        from: '# RYBA Hive HCatalog START'
        to: '# RYBA Hive HCatalog END'
        append: true
        eof: true
        backup: true
      , next

    module.exports.push name: 'Hive & HCat Server # Libs', handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      return next() unless hive.libs.length
      uploads = for lib in hive.libs
        source: lib
        destination: "/usr/hdp/current/hive-metastore/lib/#{path.basename lib}"
      ctx.upload uploads, next

    module.exports.push name: 'Hive & HCat Server # Driver', handler: (ctx, next) ->
      ctx.link
        source: '/usr/share/java/mysql-connector-java.jar'
        destination: '/usr/hdp/current/hive-metastore/lib/mysql-connector-java.jar'
      , next

    module.exports.push name: 'Hive & HCat Server # Kerberos', handler: (ctx, next) ->
      {hive, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: hive.site['hive.metastore.kerberos.principal'].replace '_HOST', ctx.config.host
        randkey: true
        keytab: hive.site['hive.metastore.kerberos.keytab.file']
        uid: hive.user.name
        gid: hive.group.name
        mode: 0o0600
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

    module.exports.push name: 'Hive & HCat Server # Logs', handler: (ctx, next) ->
      ctx.write [
        source: "#{__dirname}/../../resources/hive/hive-exec-log4j.properties.template"
        local_source: true
        destination: '/etc/hive/conf/hive-exec-log4j.properties'
      ,
        source: "#{__dirname}/../../resources/hive/hive-log4j.properties.template"
        local_source: true
        destination: '/etc/hive/conf/hive-log4j.properties'
      ], next

    module.exports.push name: 'Hive & HCat Server # Layout', timeout: -1, handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      # Required by service "hive-hcatalog-server"
      ctx.mkdir [
        destination: '/var/log/hive-hcatalog'
        uid: hive.user.name
        gid: hive.group.name
        parent: true
      ,
        destination: hive.hcatalog_pid_dir
        uid: hive.user.name
        gid: hive.group.name
        parent: true
      ]
      , next

    module.exports.push name: 'Hive & HCat Server # HDFS Layout', timeout: -1, handler: (ctx, next) ->
      # todo: this isnt pretty, ok that we need to execute hdfs command from an hadoop client
      # enabled environment, but there must be a better way
      {active_nn_host, hdfs, hive} = ctx.config.ryba
      hive_user = hive.user.name
      hive_group = hive.group.name
      cmd = mkcmd.hdfs ctx, "hdfs dfs -test -d /user && hdfs dfs -test -d /apps && hdfs dfs -test -d /tmp"
      ctx.waitForExecution cmd, code_skipped: 1, (err) ->
        modified = false
        do_user = ->
          ctx.execute
            cmd: mkcmd.hdfs ctx, """
            if hdfs dfs -ls /user/#{hive_user} &>/dev/null; then exit 1; fi
            hdfs dfs -mkdir /user/#{hive_user}
            hdfs dfs -chown #{hive_user}:#{hdfs.user.name} /user/#{hive_user}
            """
            code_skipped: 1
          , (err, executed, stdout) ->
            return next err if err
            modified = true if executed
            do_warehouse()
        do_warehouse = ->
          ctx.execute
            cmd: mkcmd.hdfs ctx, """
            if hdfs dfs -ls /apps/#{hive_user}/warehouse &>/dev/null; then exit 3; fi
            hdfs dfs -mkdir /apps/#{hive_user}
            hdfs dfs -mkdir /apps/#{hive_user}/warehouse
            hdfs dfs -chown -R #{hive_user}:#{hdfs.user.name} /apps/#{hive_user}
            hdfs dfs -chmod 755 /apps/#{hive_user}
            hdfs dfs -chmod 1777 /apps/#{hive_user}/warehouse
            """
            code_skipped: 3
          , (err, executed, stdout) ->
            return next err if err
            modified = true if executed
            do_scratch()
        do_scratch = ->
          ctx.execute
            cmd: mkcmd.hdfs ctx, """
            if hdfs dfs -ls /tmp/scratch &> /dev/null; then exit 1; fi
            hdfs dfs -mkdir /tmp 2>/dev/null
            hdfs dfs -mkdir /tmp/scratch
            hdfs dfs -chown #{hive_user}:#{hdfs.user.name} /tmp/scratch
            hdfs dfs -chmod -R 1777 /tmp/scratch
            """
            code_skipped: 1
          , (err, executed, stdout) ->
            return next err if err
            modified = true if executed
            do_end()
        do_end = ->
          next null, modified
        do_warehouse()

    module.exports.push name: 'Hive & HCat Server # Tez Package', timeout: -1, handler: (ctx, next) ->
      return next() unless ctx.hosts_with_module 'ryba/tez'
      ctx.service
        name: 'tez'
      , next

    module.exports.push name: 'Hive & HCat Server # Tez Layout', timeout: -1, handler: (ctx, next) ->
      return next() unless ctx.hosts_with_module 'ryba/tez'
      {hive, hadoop_group} = ctx.config.ryba
      version_local = 'ls /usr/hdp/current/hive-metastore/lib | grep hive-exec- | sed \'s/^hive-exec-\\(.*\\)\\.jar$/\\1/g\''
      version_remote = 'hdfs dfs -ls /apps/hive/install/hive-exec-* | sed \'s/.*\\/hive-exec-\\(.*\\)\\.jar$/\\1/g\''
      ctx.execute
        cmd: mkcmd.hdfs ctx, """
        hdfs dfs -mkdir -p /apps/hive/install 2>/dev/null
        hdfs dfs -chown #{hive.user.name}:#{hadoop_group.name} /apps/hive/install
        hdfs dfs -chmod -R 1777 /apps/hive/install
        hdfs dfs -rm -skipTrash '/apps/hive/install/hive-exec-*'
        hdfs dfs -copyFromLocal /usr/hdp/current/hive-metastore/lib/hive-exec-* /apps/hive/install
        """
        # code_skipped: 1
        not_if_exec: "[[ `#{version_local}` == `#{version_remote}` ]]"
      , next

# Module Dependencies

    path = require 'path'
    parse_jdbc = require '../../lib/parse_jdbc'
    mkcmd = require '../../lib/mkcmd'
