
# Hive HCatalog Install

TODO: Implement lock for Hive Server2
http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_18_5.html

    module.exports =  header: 'Hive HCatalog Install', handler: ->
      tez_ctxs = @contexts 'ryba/tez'
      ranger_admin = @contexts 'ryba/ranger/admin'
      {hive, realm, active_nn_host, hdfs, hadoop_group, ssl} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      tez_is_installed = if tez_ctxs.length >= 1 then true else false
      {hive} = @config.ryba
      tmp_location = "/var/tmp/ryba/ssl"

## Register

      @register 'hconfigure', 'ryba/lib/hconfigure'
      @register 'hdp_select', 'ryba/lib/hdp_select'
      @register 'hdfs_upload', 'ryba/lib/hdfs_upload'

## IPTables

| Service        | Port  | Proto | Parameter            |
|----------------|-------|-------|----------------------|
| Hive Metastore | 9083  | http  | hive.metastore.uris  |
| Hive Web UI    | 9999  | http  | hive.hwi.listen.port |


IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

      rules =  [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 9083, protocol: 'tcp', state: 'NEW', comment: "Hive Metastore" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 9999, protocol: 'tcp', state: 'NEW', comment: "Hive Web UI" }
        ]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: parseInt(hive.hcatalog.env["JMXPORT"],10), protocol: 'tcp', state: 'NEW', comment: "Metastore JMX" } if hive.hcatalog.env["JMXPORT"]?
      @iptables
        header: 'IPTables'
        rules: rules
        if: @config.iptables.action is 'start'

## Users & Groups

By default, the "hive" and "hive-hcatalog" packages create the following
entries:

```bash
cat /etc/passwd | grep hive
hive:x:493:493:Hive:/var/lib/hive:/sbin/nologin
cat /etc/group | grep hive
hive:x:493:
```

      @group hive.group
      @user hive.user

## Startup

Install the "hive-hcatalog-server" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

Note, the server is not activated on startup but they endup as zombies if HDFS
isnt yet started.

      @call header: 'Service', ->
        @call
          if: hive.hcatalog.db.engine is 'mysql'
        , ->
            @service
              name: 'mysql'
            @service
              name: 'mysql-connector-java'
        @call 
          if: hive.hcatalog.db.engine is 'postgres'
        , ->
            @service
              name: 'postgresql'
            @service
              name: 'postgresql-jdbc'
        @service
          name: 'hive'
        @hdp_select
          name: 'hive-webhcat'
        @service
          name: 'hive-hcatalog-server'
        @hdp_select
          name: 'hive-metastore'
        @render
          header: 'Init Script'
          source: "#{__dirname}/../resources/hive-hcatalog-server.j2"
          local_source: true
          target: '/etc/init.d/hive-hcatalog-server'
          context: @config.ryba
          mode: 0o0755
          unlink: true
        @execute
          cmd: "service hive-hcatalog-server restart"
          if: -> @status -3

      @call header: 'Metastore DB', timeout:-1, ->
        @db.user hive.hcatalog.db, database: null,
          header: 'User'
          if: hive.hcatalog.db.engine in ['mysql', 'postgres']
        @db.database hive.hcatalog.db,
          header: 'Database'
          if: hive.hcatalog.db.engine in ['mysql', 'postgres']
          user: hive.hcatalog.db.username
        @db.schema hive.hcatalog.db,
          header: 'Schema'
          if: hive.hcatalog.db.engine is 'postgres'
          schema: hive.hcatalog.db.schema or hive.hcatalog.db.database
          database: hive.hcatalog.db.database
          owner: hive.hcatalog.db.username
        # Metastore schema migration
        target_version = 'ls /usr/hdp/current/hive-metastore/lib | grep hive-common- | sed \'s/^hive-common-\\([0-9]\\+.[0-9]\\+.[0-9]\\+\\).*\\.jar$/\\1/g\''
        current_version = db.cmd hive.hcatalog.db, admin_username: null, 'select \\"SCHEMA_VERSION\\" from \\"VERSION\\"'
        @execute
          cmd: """
          engine="#{hive.hcatalog.db.engine}"
          cd /usr/hdp/current/hive-metastore/scripts/metastore/upgrade/${engine} # Required for sql sources
          target_version=`#{target_version}`
          echo Target Version: "$target_version"
          target=hive-schema-${target_version}.${engine}.sql
          target_major_version=`echo $target_version | sed \'s/^\\([0-9]\\+\\).\\([0-9]\\+\\).\\([0-9]\\+\\)$/\\1.\\2.0/g\'`
          echo Target Version: "$target_major_version"
          target_major=hive-schema-${target_major_version}.${engine}.sql
          if ! test -f $target && ! test -f $target_major; then exit 1; fi
          # Create schema
          if test -f $target; then
            echo Importing $target
            #{db.cmd hive.hcatalog.db, admin_username: null, null} < $target;
          elif test -f $target_major; then
            echo Importing $target_major
            #{db.cmd hive.hcatalog.db, admin_username: null, null} < $target_major;
          fi
          """
          trap: true
        @execute
          header: 'Upgrade'
          cmd: """
          engine="#{hive.hcatalog.db.engine}"
          cd /usr/hdp/current/hive-metastore/scripts/metastore/upgrade/${engine} # Required for sql sources
          current=`#{current_version}`
          echo Current Version: "$current"
          target=`#{target_version}`
          echo Target Version: "$target"
          if [ "$current" == "$target" ]; then exit 3; fi
          # Upgrade schema
          upgrade=upgrade-${current}-to-${target}.${engine}.sql
          if ! test -f $upgrade; then
            echo 'Upgrade script does not exists'
            current_major=`echo $target | sed \'s/^\\([0-9]\\+\\).\\([0-9]\\+\\).\\([0-9]\\+\\)$/\\1.\\2/g\'`
            target_major=`echo $target | sed \'s/^\\([0-9]\\+\\).\\([0-9]\\+\\).\\([0-9]\\+\\)$/\\1.\\2/g\'`
            echo Target Major Version: "$target_major"
            if [ $current_major == $target_major ]; then exit 0; fi
            exit 1;
          fi
          cd `dirname $upgrade`
          #{db.cmd hive.hcatalog.db, admin_username: null, null} < $upgrade
          # Import transaction schema (now created with 0.13.1)
          #trnx=hive-txn-schema-${target}.${engine}.sql
          #if test -f $trnx; then #{db.cmd hive.hcatalog.db, admin_username: null, null} < $trnx; fi
          """
          trap: true
          code_skipped: 3
      @hconfigure
        header: 'Hive Site'
        target: "#{hive.hcatalog.conf_dir}/hive-site.xml"
        source: "#{__dirname}/../../resources/hive/hive-site.xml"
        local_source: true
        properties: hive.hcatalog.site
        merge: true
        backup: true
      @file.properties
        header: 'Hive server Log4j properties'
        target: "#{hive.hcatalog.conf_dir}/hive-log4j.properties"
        content: hive.hcatalog.log4j.config
        backup: true
      @render
        header: 'Exec Log4j'
        target: "#{hive.hcatalog.conf_dir}/hive-exec-log4j.properties"
        source: "#{__dirname}/../resources/hive-exec-log4j.properties"
        local_source: true
        context: @config
      @execute
        header: 'Directory Permission'
        cmd: """
        chown -R #{hive.user.name}:#{hive.group.name} #{hive.hcatalog.conf_dir}/
        chmod -R 755 #{hive.hcatalog.conf_dir}
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

      @render
        header: 'Hive Env'
        source: "#{__dirname}/../resources/hive-env.sh.j2"
        target: "#{hive.hcatalog.conf_dir}/hive-env.sh"
        local_source: true
        context: @config
        eof: true
        mode: 0o750
        backup: true
        write: [
          match: RegExp "^export HIVE_CONF_DIR=.*$", 'mg'
          replace: "export HIVE_CONF_DIR=#{hive.hcatalog.conf_dir}"
        ]
      @call
        header: 'Upload Libs'
        if: -> hive.libs.length
      , ->
          @file.download (
            source: lib
            target: "/usr/hdp/current/hive-metastore/lib/#{path.basename lib}"
          ) for lib in hive.libs
      @link
        if: hive.hcatalog.db.engine is 'mysql'
        header: 'Link MySQL Driver'
        source: '/usr/share/java/mysql-connector-java.jar'
        target: '/usr/hdp/current/hive-metastore/lib/mysql-connector-java.jar'
      @link
        if: hive.hcatalog.db.engine is 'postgres'
        header: 'Link PostgreSQL Driver'
        source: '/usr/share/java/postgresql-jdbc.jar'
        target: '/usr/hdp/current/hive-metastore/lib/postgresql-jdbc.jar'

## Kerberos

      @krb5_addprinc krb5,
        header: 'Kerberos'
        principal: hive.hcatalog.site['hive.metastore.kerberos.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: hive.hcatalog.site['hive.metastore.kerberos.keytab.file']
        uid: hive.user.name
        gid: hive.group.name
        mode: 0o0600

## Layout

Create the directories to store the logs and pid information. The properties
"ryba.hive.hcatalog.log\_dir" and "ryba.hive.hcatalog.pid\_dir" may be modified.

      @call header: 'Layout', timeout: -1, ->
        @mkdir
          target: hive.hcatalog.log_dir
          uid: hive.user.name
          gid: hive.group.name
          parent: true
        @mkdir
          target: hive.hcatalog.pid_dir
          uid: hive.user.name
          gid: hive.group.name
          parent: true

      @call header: 'HDFS Layout', timeout: -1, ->
        # todo: this isnt pretty, ok that we need to execute hdfs command from an hadoop client
        # enabled environment, but there must be a better way
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
          """
          code_skipped: 3
        @execute
          cmd: mkcmd.hdfs @, "hdfs dfs -chmod -R #{hive.warehouse_mode or '1777'} /apps/#{hive_user}/warehouse"
        @execute
          cmd: mkcmd.hdfs @, """
          if hdfs dfs -ls /tmp/scratch &> /dev/null; then exit 1; fi
          hdfs dfs -mkdir /tmp 2>/dev/null
          hdfs dfs -mkdir /tmp/scratch
          hdfs dfs -chown #{hive_user}:#{hdfs.user.name} /tmp/scratch
          hdfs dfs -chmod -R 1777 /tmp/scratch
          """
          code_skipped: 1

## Tez

      @service
        header: 'Tez Package'
        name: 'tez'
        if: -> tez_ctxs.length
      @execute
        header: 'Tez Layout'
        if: -> tez_ctxs.length
        timeout: -1
        cmd: 'ls /usr/hdp/current/hive-metastore/lib | grep hive-exec- | sed \'s/^hive-exec-\\(.*\\)\\.jar$/\\1/g\''
        shy: true
      , (err, status, stdout) ->
        version = stdout.trim() unless err
        @hdfs_upload
          source: "/usr/hdp/current/hive-metastore/lib/hive-exec-#{version}.jar"
          target: "/apps/hive/install/hive-exec-#{version}.jar"
          clean: "/apps/hive/install/hive-exec-*.jar"
          lock: "/tmp/hive-exec-#{version}.jar"

## SSL

      @call header: 'Client SSL', ->
        @download
          source: ssl.cacert
          target: "#{tmp_location}/#{path.basename ssl.cacert}"
          mode: 0o0600
          shy: true
        @java_keystore_add
          keystore: hive.hcatalog.truststore_location
          storepass: hive.hcatalog.truststore_password
          caname: "hive_root_ca"
          cacert: "#{tmp_location}/#{path.basename ssl.cacert}"
        @remove
          target: "#{tmp_location}/#{path.basename ssl.cacert}"
          shy: true

## Ulimit

      @system_limits
        user: hive.user.name
        nofile: hive.user.limits.nofile
        nproc: hive.user.limits.nproc

# Module Dependencies

    path = require 'path'
    db = require 'mecano/lib/misc/db'
    mkcmd = require '../../lib/mkcmd'
