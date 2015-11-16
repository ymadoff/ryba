
# Hive HCatalog Install

TODO: Implement lock for Hive Server2
http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_18_5.html

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/krb5_client'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/mysql_client' # Install the mysql connector
    module.exports.push 'ryba/hadoop/mapred_client/install'
    module.exports.push 'ryba/tez/install'
    module.exports.push 'ryba/hive/client/install' # Install the Hive and HCatalog service
    module.exports.push 'ryba/hadoop/hdfs_dn/wait'
    module.exports.push 'ryba/hbase/client/install'
    module.exports.push 'ryba/lib/hconfigure'
    module.exports.push 'ryba/lib/hdp_select'
    # module.exports.push require('./index').configure

## IPTables

| Service        | Port  | Proto | Parameter            |
|----------------|-------|-------|----------------------|
| Hive Metastore | 9083  | http  | hive.metastore.uris  |
| Hive Web UI    | 9999  | http  | hive.hwi.listen.port |


IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push header: 'Hive HCatalog # IPTables', handler: ->
      {hive} = @config.ryba
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 9083, protocol: 'tcp', state: 'NEW', comment: "Hive Metastore" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 9999, protocol: 'tcp', state: 'NEW', comment: "Hive Web UI" }
        ]
        if: @config.iptables.action is 'start'

## Startup

Install the "hive-hcatalog-server" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

Note, the server is not activated on startup but they endup as zombies if HDFS
isnt yet started.

    module.exports.push header: 'Hive HCatalog # Startup', handler: ->
      @service
        name: 'hive-hcatalog-server'
      @hdp_select
        name: 'hive-metastore'
      @write
        source: "#{__dirname}/../resources/hive-hcatalog-server"
        local_source: true
        destination: '/etc/init.d/hive-hcatalog-server'
        mode: 0o0755
        unlink: true
      @execute
        cmd: "service hive-hcatalog-server restart"
        if: -> @status -3

    module.exports.push header: 'Hive HCatalog # Database', handler: ->
      {hive, db_admin} = @config.ryba
      username = hive.site['javax.jdo.option.ConnectionUserName']
      password = hive.site['javax.jdo.option.ConnectionPassword']
      {engine, host, db} = parse_jdbc hive.site['javax.jdo.option.ConnectionURL']
      switch engine
        when 'mysql'
          mysql_admin = "#{db_admin.path} -u#{db_admin.username} -p#{db_admin.password} -h#{db_admin.host} -P#{db_admin.port}"
          mysql_client = "#{db_admin.path} -u#{username} -p#{password} -h#{db_admin.host} -P#{db_admin.port}"
          target_version = 'ls /usr/hdp/current/hive-metastore/lib | grep hive-common- | sed \'s/^hive-common-\\([0-9]\\+.[0-9]\\+.[0-9]\\+\\).*\\.jar$/\\1/g\''
          current_version = "#{mysql_client} -e 'select SCHEMA_VERSION from hive.VERSION' --skip-column-names"
          @execute
            cmd: "if ! #{mysql_client} -e \"USE #{db};\"; then exit 3; fi"
            code_skipped: 3
          @execute
            cmd: """
            #{mysql_admin} -e "
            create database if not exists #{db};
            grant all privileges on #{db}.* to '#{username}'@'localhost' identified by '#{password}';
            grant all privileges on #{db}.* to '#{username}'@'%' identified by '#{password}';
            flush privileges;
            "
            """
            unless: -> @status -1
            trap_on_error: true
          @execute
            cmd: """
            cd /usr/hdp/current/hive-metastore/scripts/metastore/upgrade/mysql # Required for sql sources
            target_version=`#{target_version}`
            echo Target Version: "$target_version"
            target=hive-schema-${target_version}.mysql.sql
            target_major_version=`echo $target_version | sed \'s/^\\([0-9]\\+\\).\\([0-9]\\+\\).\\([0-9]\\+\\)$/\\1.\\2.0/g\'`
            echo Target Version: "$target_major_version"
            target_major=hive-schema-${target_major_version}.mysql.sql
            if ! test -f $target && ! test -f $target_major; then exit 1; fi
            # Create schema
            if test -f $target; then
              echo Importing $target
              #{mysql_client} #{db} < $target;
            elif test -f $target_major; then
              echo Importing $target_major
              #{mysql_client} #{db} < $target_major;
            fi
            """
            unless: -> @status -2
            trap_on_error: true
          @execute
            cmd: """
            cd /usr/hdp/current/hive-metastore/scripts/metastore/upgrade/mysql # Required for sql sources
            current=`#{current_version}`
            echo Current Version: "$current"
            target=`#{target_version}`
            echo Target Version: "$target"
            if [ "$current" == "$target" ]; then exit 3; fi
            # Upgrade schema
            upgrade=upgrade-${current}-to-${target}.mysql.sql
            if ! test -f $upgrade; then
              echo 'Upgrade script does not exists'
              current_major=`echo $target | sed \'s/^\\([0-9]\\+\\).\\([0-9]\\+\\).\\([0-9]\\+\\)$/\\1.\\2/g\'`
              target_major=`echo $target | sed \'s/^\\([0-9]\\+\\).\\([0-9]\\+\\).\\([0-9]\\+\\)$/\\1.\\2/g\'`
              echo Target Major Version: "$target_major"
              if [ $current_major == $target_major ]; then exit 0; fi
              exit 1;
            fi
            cd `dirname $upgrade`
            #{mysql_client} #{db} < $upgrade
            # Import transaction schema (now created with 0.13.1)
            #trnx=hive-txn-schema-${target}.mysql.sql
            #if test -f $trnx; then #{mysql_client} #{db} < $trnx; fi
            """
            code_skipped: 3
            trap_on_error: true
            unless: -> @status -3
        else throw new Error 'Database engine not supported'

    module.exports.push header: 'Hive HCatalog # Configure', handler: ->
      {hive} = @config.ryba
      @hconfigure
        destination: "#{hive.conf_dir}/hive-site.xml"
        default: "#{__dirname}/../../resources/hive/hive-site.xml"
        local_default: true
        properties: hive.site
        merge: true
        backup: true
      @execute
        cmd: """
        chown -R #{hive.user.name}:#{hive.group.name} #{hive.conf_dir}/
        chmod -R 755 #{hive.conf_dir}
        """
        shy: true # TODO: idempotence by detecting ownerships and permissions

## Env

Enrich the "hive-env.sh" file with the value of the configuration properties
"ryba.hive.hcatalog.opts" and "ryba.hive.hcatalog.heapsize". Internally, the
environmental variables "HADOOP_CLIENT_OPTS" and "HADOOP_HEAPSIZE" are enriched
and they only apply to the Hive HCatalog server.

Using this functionnality, a user may for example raise the heap size of Hive
HCatalog to 4Gb by either setting a "opts" value equal to "-Xmx4096m" or the 
by setting a "heapsize" value equal to "4096".

Note, the startup script found in "hive-hcatalog/bin/hcat_server.sh" references
the Hive Metastore service and execute "./bin/hive --service metastore"

    module.exports.push header: 'Hive HCatalog # Env', handler: ->
      {hive} = @config.ryba
      @write
        destination: "#{hive.conf_dir}/hive-env.sh"
        replace: """
        if [ "$SERVICE" = "metastore" ]; then
          # export HADOOP_CLIENT_OPTS="-Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=130.98.196.54 -Dcom.sun.management.jmxremote.rmi.port=9526 -Dcom.sun.management.jmxremote.port=9526 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false  $HADOOP_CLIENT_OPTS"
          export HADOOP_HEAPSIZE="#{hive.hcatalog.heapsize}"
          export HADOOP_CLIENT_OPTS="-Xmx${HADOOP_HEAPSIZE}m #{hive.hcatalog.opts} $HADOOP_CLIENT_OPTS"
        fi
        """
        from: '# RYBA HIVE HCATALOG START'
        to: '# RYBA HIVE HCATALOG END'
        append: true
        eof: true
        backup: true

    module.exports.push
      header: 'Hive HCatalog # Libs'
      if: -> @config.ryba.hive.libs.length
      handler: ->
        {hive} = @config.ryba
        @upload (
          for lib in hive.libs
            source: lib
            destination: "/usr/hdp/current/hive-metastore/lib/#{path.basename lib}"
        )

    module.exports.push header: 'Hive HCatalog # Driver', handler: ->
      @link
        source: '/usr/share/java/mysql-connector-java.jar'
        destination: '/usr/hdp/current/hive-metastore/lib/mysql-connector-java.jar'

    module.exports.push header: 'Hive HCatalog # Kerberos', handler: ->
      {hive, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: hive.site['hive.metastore.kerberos.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: hive.site['hive.metastore.kerberos.keytab.file']
        uid: hive.user.name
        gid: hive.group.name
        mode: 0o0600
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

    module.exports.push header: 'Hive HCatalog # Logs', handler: ->
      @write
        source: "#{__dirname}/../../resources/hive/hive-exec-log4j.properties.template"
        local_source: true
        destination: '/etc/hive/conf/hive-exec-log4j.properties'
      @write
        source: "#{__dirname}/../../resources/hive/hive-log4j.properties.template"
        local_source: true
        destination: '/etc/hive/conf/hive-log4j.properties'

## Layout

Create the directories to store the logs and pid information. The properties
"ryba.hive.hcatalog.log\_dir" and "ryba.hive.hcatalog.pid\_dir" may be modified.

    module.exports.push header: 'Hive HCatalog # Layout', timeout: -1, handler: ->
      {hive} = @config.ryba
      # Required by service "hive-hcatalog-server"
      @mkdir
        destination: hive.hcatalog.log_dir
        uid: hive.user.name
        gid: hive.group.name
        parent: true
      @mkdir
        destination: hive.hcatalog.pid_dir
        uid: hive.user.name
        gid: hive.group.name
        parent: true

    module.exports.push header: 'Hive HCatalog # HDFS Layout', timeout: -1, handler: ->
      # todo: this isnt pretty, ok that we need to execute hdfs command from an hadoop client
      # enabled environment, but there must be a better way
      {active_nn_host, hdfs, hive} = @config.ryba
      hive_user = hive.user.name
      hive_group = hive.group.name
      cmd = mkcmd.hdfs @, "hdfs dfs -test -d /user && hdfs dfs -test -d /apps && hdfs dfs -test -d /tmp"
      @wait_execute
        cmd: cmd
        code_skipped: 1
      @execute
        cmd: mkcmd.hdfs @, """
        if hdfs dfs -ls /user/#{hive_user} &>/dev/null; then exit 1; fi
        hdfs dfs -mkdir /user/#{hive_user}
        hdfs dfs -chown #{hive_user}:#{hdfs.user.name} /user/#{hive_user}
        """
        code_skipped: 1
        if: false # Disabled
      @execute
        cmd: mkcmd.hdfs @, """
        if hdfs dfs -ls /apps/#{hive_user}/warehouse &>/dev/null; then exit 3; fi
        hdfs dfs -mkdir /apps/#{hive_user}
        hdfs dfs -mkdir /apps/#{hive_user}/warehouse
        hdfs dfs -chown -R #{hive_user}:#{hdfs.user.name} /apps/#{hive_user}
        hdfs dfs -chmod 755 /apps/#{hive_user}
        hdfs dfs -chmod 1777 /apps/#{hive_user}/warehouse
        """
        code_skipped: 3
      @execute
        cmd: mkcmd.hdfs @, """
        if hdfs dfs -ls /tmp/scratch &> /dev/null; then exit 1; fi
        hdfs dfs -mkdir /tmp 2>/dev/null
        hdfs dfs -mkdir /tmp/scratch
        hdfs dfs -chown #{hive_user}:#{hdfs.user.name} /tmp/scratch
        hdfs dfs -chmod -R 1777 /tmp/scratch
        """
        code_skipped: 1

    module.exports.push
      header: 'Hive HCatalog # Tez Package'
      timeout: -1
      if: -> @hosts_with_module 'ryba/tez'
      handler: ->
        @service name: 'tez'

    module.exports.push
      header: 'Hive HCatalog # Tez Layout'
      timeout: -1
      if: -> @hosts_with_module 'ryba/tez'
      handler: ->
        {hive, hadoop_group} = @config.ryba
        version_local = 'ls /usr/hdp/current/hive-metastore/lib | grep hive-exec- | sed \'s/^hive-exec-\\(.*\\)\\.jar$/\\1/g\''
        version_remote = 'hdfs dfs -ls /apps/hive/install/hive-exec-* | sed \'s/.*\\/hive-exec-\\(.*\\)\\.jar$/\\1/g\''
        @execute
          cmd: mkcmd.hdfs @, """
          hdfs dfs -mkdir -p /apps/hive/install 2>/dev/null
          hdfs dfs -chown #{hive.user.name}:#{hadoop_group.name} /apps/hive/install
          hdfs dfs -chmod -R 1777 /apps/hive/install
          hdfs dfs -rm -skipTrash '/apps/hive/install/hive-exec-*'
          hdfs dfs -copyFromLocal /usr/hdp/current/hive-metastore/lib/hive-exec-* /apps/hive/install
          hdfs dfs -chown #{hive.user.name}:#{hadoop_group.name} /apps/hive/install/hive-exec-*
          """
          unless_exec: "[[ `#{version_local}` == `#{version_remote}` ]]"

# Module Dependencies

    path = require 'path'
    parse_jdbc = require '../../lib/parse_jdbc'
    mkcmd = require '../../lib/mkcmd'
