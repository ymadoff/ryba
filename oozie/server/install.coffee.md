
# Oozie Server Install

Oozie source code and examples are located in "/usr/share/doc/oozie-$version".

The current version of Oozie doesnt supported automatic failover of the Yarn
Resource Manager. RM HA (High Availability) must be configure with manual
failover and Oozie must target the active node. 

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/mysql_client'
    module.exports.push 'ryba/hadoop/core'
    module.exports.push 'ryba/hadoop/hdfs' # SPNEGO need access to the principal HTTP/$HOST@$REALM's keytab
    module.exports.push 'ryba/hadoop/hdfs_dn/wait' # Create directories inside HDFS
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdp_select'
    module.exports.push require('./index').configure

## Users & Groups

By default, the "oozie" package create the following entries:

```bash
cat /etc/passwd | grep oozie
oozie:x:493:493:Oozie User:/var/lib/oozie:/bin/bash
cat /etc/group | grep oozie
oozie:x:493:
```

    module.exports.push name: 'Oozie Server # Users & Groups', handler: (ctx, next) ->
      {oozie} = ctx.config.ryba
      ctx
      .group oozie.group
      .user oozie.user
      .then next

## IPTables

| Service | Port  | Proto | Info                      |
|---------|-------|-------|---------------------------|
| oozie   | 11443 | http  | Oozie HTTP secure server  |
| oozie   | 11001 | http  | Oozie Admin server        |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'Oozie Server # IPTables', handler: (ctx, next) ->
      {oozie} = ctx.config.ryba
      port = url.parse(oozie.site['oozie.base.url']).port
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'tcp', state: 'NEW', comment: "Oozie HTTP Server" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: oozie.admin_port, protocol: 'tcp', state: 'NEW', comment: "Oozie HTTP Server" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

    module.exports.push name: 'Oozie Server # Install', timeout: -1, handler: (ctx, next) ->
      # Upgrading oozie failed, tested versions are hdp 2.1.2 -> 2.1.5 -> 2.1.7
      ctx
      .execute
        cmd: "rm -rf /usr/lib/oozie && yum remove -y oozie oozie-client"
        if: ctx.retry > 0
      .service
        name: 'falcon'
        if: ctx.hosts_with_module('ryba/falcon').length
      .service
        name: 'unzip' # Required by the "prepare-war" command
      .service
        name: 'zip' # Required by the "prepare-war" command
      .service
        name: 'extjs-2.2-1'
      # @call if: ctx.contexts('ryba/falcon').length, ->
      #   @service
      #     name: 'falcon'
      #   @hdp_select
      #     name: 'falcon-client'
      @service
        name: 'falcon'
        if: ctx.contexts('ryba/falcon').length
      @hdp_select
        name: 'falcon-client'
        if: ctx.contexts('ryba/falcon').length
      .service
        name: 'oozie' # Also install oozie-client and bigtop-tomcat
      .hdp_select
        name: 'oozie-server'
      .hdp_select
        name: 'oozie-client'
      .write
        source: "#{__dirname}/../resources/oozie"
        local_source: true
        destination: '/etc/init.d/oozie'
        mode: 0o0755
        unlink: true
      .execute
        cmd: "service oozie-server restart"
        if: -> @status -4
      .then next

    module.exports.push name: 'Oozie Server # Directories', handler: (ctx, next) ->
      {hadoop_group, oozie} = ctx.config.ryba
      ctx
      .mkdir
        destination: oozie.data
        uid: oozie.user.name
        gid: hadoop_group.name
        mode: 0o0755
      .mkdir
        destination: oozie.log_dir
        uid: oozie.user.name
        gid: hadoop_group.name
        mode: 0o0755
      .mkdir
        destination: oozie.pid_dir
        uid: oozie.user.name
        gid: hadoop_group.name
        mode: 0o0755
      .mkdir
        destination: oozie.tmp_dir
        uid: oozie.user.name
        gid: hadoop_group.name
        mode: 0o0755
      .mkdir
        destination: "#{oozie.conf_dir}/action-conf"
        uid: oozie.user.name
        gid: hadoop_group.name
        mode: 0o0755
      # Set permission to action conf
      .execute
        cmd: """
        chown -R #{oozie.user.name}:#{hadoop_group.name} #{oozie.conf_dir}/action-conf
        """
        shy: true
      .then next
      # Waiting for recursivity in ctx.mkdir
      # ctx.execute
      #   cmd: """
      #   chown -R #{oozie.user.name}:#{hadoop_group.name} /usr/lib/oozie
      #   chown -R #{oozie.user.name}:#{hadoop_group.name} #{oozie.data}
      #   chown -R #{oozie.user.name}:#{hadoop_group.name} #{oozie.conf_dir} #/..
      #   chmod -R 755 #{oozie.conf_dir} #/..
      #   """
      # , (err, executed) ->
      #   next err, copied

## Environment

Update the Oozie environment file "oozie-env.sh" located inside
"/etc/oozie/conf".

Note, environment variables are grabed by oozie and translated into java
properties inside "./bin/oozied.distro". Here's an extract:


```bash
catalina_opts="-Doozie.home.dir=${OOZIE_HOME}";
catalina_opts="${catalina_opts} -Doozie.config.dir=${OOZIE_CONFIG}";
catalina_opts="${catalina_opts} -Doozie.log.dir=${OOZIE_LOG}";
catalina_opts="${catalina_opts} -Doozie.data.dir=${OOZIE_DATA}";
catalina_opts="${catalina_opts} -Doozie.instance.id=${OOZIE_INSTANCE_ID}"
catalina_opts="${catalina_opts} -Doozie.config.file=${OOZIE_CONFIG_FILE}";
catalina_opts="${catalina_opts} -Doozie.log4j.file=${OOZIE_LOG4J_FILE}";
catalina_opts="${catalina_opts} -Doozie.log4j.reload=${OOZIE_LOG4J_RELOAD}";
catalina_opts="${catalina_opts} -Doozie.http.hostname=${OOZIE_HTTP_HOSTNAME}";
catalina_opts="${catalina_opts} -Doozie.admin.port=${OOZIE_ADMIN_PORT}";
catalina_opts="${catalina_opts} -Doozie.http.port=${OOZIE_HTTP_PORT}";
catalina_opts="${catalina_opts} -Doozie.https.port=${OOZIE_HTTPS_PORT}";
catalina_opts="${catalina_opts} -Doozie.base.url=${OOZIE_BASE_URL}";
catalina_opts="${catalina_opts} -Doozie.https.keystore.file=${OOZIE_HTTPS_KEYSTORE_FILE}";
catalina_opts="${catalina_opts} -Doozie.https.keystore.pass=${OOZIE_HTTPS_KEYSTORE_PASS}";
```

    module.exports.push name: 'Oozie Server # Environment', handler: (ctx, next) ->
      {java_home} = ctx.config.java
      {oozie} = ctx.config.ryba
      # CATALINA_OPTS="-Djavax.net.ssl.trustStore=/etc/hadoop/conf/truststore -Djavax.net.ssl.trustStorePassword=ryba123"      
      writes = [
          match: /^export OOZIE_HTTPS_KEYSTORE_FILE=.*$/mg
          replace: "export OOZIE_HTTPS_KEYSTORE_FILE=#{oozie.keystore_file}"
          append: true
        ,
          match: /^export OOZIE_HTTPS_KEYSTORE_PASS=.*$/mg
          replace: "export OOZIE_HTTPS_KEYSTORE_PASS=#{oozie.keystore_pass}"
          append: true
        ,
          match: /^export OOZIE_LOG=.*$/mg
          replace: "export OOZIE_LOG=#{oozie.log_dir}"
          append: true
        ]
      # Append the Log4J configuration
      if oozie.log4j.extra_appender
        writes.push
            match: /^export CATALINA_OPTS="${CATALINA_OPTS} -Doozie.log4j.extra_appender=(.*)/m
            replace: """
            export CATALINA_OPTS="${CATALINA_OPTS} -Doozie.log4j.extra_appender=,#{oozie.log4j.extra_appender}"
            """
            append: true
        # Append the configuration of the SocketAppender
        if oozie.log4j.extra_appender == "socket_client"
          writes.push
              match: /^export CATALINA_OPTS="${CATALINA_OPTS} -Doozie.log4j.remote_host=(.*)/m
              replace: """
              export CATALINA_OPTS="${CATALINA_OPTS} -Doozie.log4j.remote_host=#{oozie.log4j.remote_host}"
              """
              append: true
            ,
              match: /^export CATALINA_OPTS="${CATALINA_OPTS} -Doozie.log4j.remote_port=(.*)/m
              replace: """
              export CATALINA_OPTS="${CATALINA_OPTS} -Doozie.log4j.remote_port=#{oozie.log4j.remote_port}"
              """
              append: true
        else
          writes.push
              match: /^export CATALINA_OPTS="${CATALINA_OPTS} -Doozie.log4j.remote_host=(.*)/m
              replace: ""  
            ,
              match: /^export CATALINA_OPTS="${CATALINA_OPTS} -Doozie.log4j.remote_port=(.*)/m
              replace: ""  
        # Append the configuration of the SocketHubAppender
        if oozie.log4j.extra_appender == "socket_server"
          writes.push
              match: /^export CATALINA_OPTS="${CATALINA_OPTS} -Doozie.log4j.server_port=(.*)/m
              replace: """
              export CATALINA_OPTS="${CATALINA_OPTS} -Doozie.log4j.server_port=#{oozie.log4j.server_port}"
              """
              append: true
        else
          writes.push
              match: /^export CATALINA_OPTS="${CATALINA_OPTS} -Doozie.log4j.server_port=(.*)/m
              replace: ""
      else   
        writes.push
            match: /^export CATALINA_OPTS="${CATALINA_OPTS} -Doozie.log4j.extra_appender=(.*)/m
            replace: ""
      @render
        source: "#{__dirname}/../resources/oozie-env.sh"
        local_source: true
        destination: "#{oozie.conf_dir}/oozie-env.sh"
        context: @config
        write: writes
        uid: oozie.user.name
        gid: oozie.group.name
        mode: 0o0755
        backup: true
      .then next

# ExtJS

Install the ExtJS Javascript library as part of enabling the Oozie Web Console.

    module.exports.push name: 'Oozie Server # ExtJS', handler: (ctx, next) ->
      ctx
      .copy
        source: '/usr/share/HDP-oozie/ext-2.2.zip'
        destination: '/usr/hdp/current/oozie-client/libext/'
      .then next

# HBase credentials

Install the HBase Libs as part of enabling the Oozie Unified Credentials with HBase.

    module.exports.push name: 'Oozie Server # HBase Libs', handler: (ctx, next) ->
      ctx
      .copy
        source: '/usr/hdp/current/hbase-client/lib/hbase-common.jar'
        destination: '/usr/hdp/current/oozie-client/libserver/'
      .then next

# LZO

Install the LZO compression library as part of enabling the Oozie Web Console.

    module.exports.push name: 'Oozie Server # LZO', handler: (ctx, next) ->
      ctx.execute
        cmd: 'ls /usr/hdp/current/share/lzo/*/lib/hadoop-lzo-*.jar'
      , (err, _, stdout) ->
        return next err if err
        lzo_jar = stdout.trim()
        ctx.execute
          cmd: """
          # Remove any previously installed version
          rm /usr/hdp/current/oozie-client/libext/hadoop-lzo-*.jar
          # Copy lzo
          cp #{lzo_jar} /usr/hdp/current/oozie-client/libext/
          """
          not_if_exists: "/usr/hdp/current/oozie-client/libext/#{path.basename lzo_jar}"
        .then next

    # Note
    # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.0/HDP_Man_Install_v22/index.html#Item1.12.4.3
    # Copy or symlink the MySQL JDBC driver JAR into the /var/lib/oozie/ directory.
    module.exports.push name: 'Oozie Server # Mysql Driver', handler: (ctx, next) ->
      ctx.link
        source: '/usr/share/java/mysql-connector-java.jar'
        destination: '/usr/hdp/current/oozie-client/libext/mysql-connector-java.jar'
      .then next

    module.exports.push name: 'Oozie Server # Configuration', handler: (ctx, next) ->
      { hadoop_conf_dir, yarn, oozie } = ctx.config.ryba
      modified = false
      do_oozie_site = ->
        ctx
        .hconfigure
          destination: "#{oozie.conf_dir}/oozie-site.xml"
          default: "#{__dirname}/../resources/oozie-site.xml"
          local_default: true
          properties: oozie.site
          uid: oozie.user.name
          gid: oozie.group.name
          mode: 0o0755
          merge: true
          backup: true
        .then (err, configured) ->
          return next err if err
          modified = true if configured
          do_oozie_default()
      do_oozie_default = ->
        ctx.upload
          destination: "#{oozie.conf_dir}/oozie-default.xml"
          source: "#{__dirname}/../../resources/oozie/oozie-default.xml"
          backup: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_hadoop_config()
      do_hadoop_config = ->
        ctx
        .hconfigure
          destination: "#{oozie.conf_dir}/hadoop-conf/core-site.xml"
          local_default: true
          properties: oozie.hadoop_config
          uid: oozie.user.name
          gid: oozie.group.name
          mode: 0o0755
          backup: true
        .then (err, configured) ->
          return next err if err
          modified = true if configured
          do_end()
      do_end = ->
        next null, modified
      do_oozie_site()

    # module.exports.push name: 'Oozie Server # SSL', handler: (ctx, next) ->
    #   {java_home, jre_home} = ctx.config.java
    #   {ssl, oozie} = ctx.config.ryba
    #   tmp_location = "/tmp/ryba_oozie_client_#{Date.now()}"
    #   ctx
    #   .upload
    #     source: ssl.cacert
    #     destination: "#{tmp_location}_cacert"
    #   .execute
    #     cmd: "su -l oozie -c 'keytool -import -alias tomcat -file #{tmp_location}_cacert'"
    #   .remove
    #     destination: "#{tmp_location}_cacert"
    #   .then next

    module.exports.push name: 'Oozie Server # War', handler: (ctx, next) ->
      {oozie} = ctx.config.ryba
      falcon_ctxs = ctx.contexts 'ryba/falcon', require('../../falcon').configure
      do_falcon = ->
        return do_prepare_war() unless falcon_ctxs.length
        ctx
        .service
          name: 'falcon'
        .mkdir
          destination: '/tmp/falcon-oozie-jars'
        # Note, the documentation mentions using "-d" option but it doesnt
        # seem to work. Instead, we deploy the jar where "-d" default.
        .execute
          # cmd: """
          # rm -rf /tmp/falcon-oozie-jars/*
          # cp  /usr/lib/falcon/oozie/ext/falcon-oozie-el-extension-*.jar \
          #   /tmp/falcon-oozie-jars
          # """, (err) ->
          cmd: """
          falconext=`ls /usr/hdp/current/falcon-client/oozie/ext/falcon-oozie-el-extension-*.jar`
          if [ -f /usr/hdp/current/oozie-client/libext/`basename $falconext` ]; then exit 3; fi
          rm -rf /tmp/falcon-oozie-jars/*
          cp  /usr/hdp/current/falcon-client/oozie/ext/falcon-oozie-el-extension-*.jar \
            /usr/hdp/current/oozie-client/libext
          """
          code_skipped: 3
        .execute
          cmd: """
          if [ ! -f #{oozie.pid_dir}/oozie.pid ]; then exit 3; fi
          if ! kill -0 >/dev/null 2>&1 `cat #{oozie.pid_dir}/oozie.pid`; then exit 3; fi
          su -l #{oozie.user.name} -c "/usr/hdp/current/oozie-server/bin/oozied.sh stop 20 -force"
          rm -rf cat #{oozie.pid_dir}/oozie.pid
          """
          code_skipped: 3
        .then (err) ->
          return next err if err
          do_prepare_war()
      do_prepare_war = ->
        # The script `ooziedb.sh` must be done as the oozie Unix user, otherwise
        # Oozie may fail to start or work properly because of incorrect file permissions.
        # There is already a "oozie.war" file inside /var/lib/oozie/oozie-server/webapps/.
        # The "prepare-war" command generate the file "/var/lib/oozie/oozie-server/webapps/oozie.war".
        # The directory being served by the web server is "prepare-war".
        # See note 20 lines above about "-d" option
        # falcon_opts = if falcon_ctxs.length then " –d /tmp/falcon-oozie-jars" else ''
        secure_opt = if oozie.secure then '-secure' else ''
        falcon_opts = ''
        ctx.execute
          # su -l oozie -c 'cd /usr/hdp/current/oozie-client; ./bin/oozie-setup.sh prepare-war -secure'
          cmd: """
          chown #{oozie.user.name} /usr/hdp/current/oozie-client/oozie-server/conf/server.xml
          su -l #{oozie.user.name} -c 'cd /usr/hdp/current/oozie-client; ./bin/oozie-setup.sh prepare-war #{secure_opt} #{falcon_opts}'
          """
          code_skipped: 255 # Oozie already started, war is expected to be installed
        , next
      do_falcon()

    module.exports.push name: 'Oozie Server # Kerberos', handler: (ctx, next) ->
      {oozie, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx
      .krb5_addprinc
        principal: oozie.site['oozie.service.HadoopAccessorService.kerberos.principal'] #.replace '_HOST', ctx.config.host
        randkey: true
        keytab: oozie.site['oozie.service.HadoopAccessorService.keytab.file']
        uid: oozie.user.name
        gid: oozie.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      .then next

    module.exports.push name: 'Oozie Server # SPNEGO', handler: (ctx, next) ->
      {oozie} = ctx.config.ryba
      ctx
      .copy
        source: '/etc/security/keytabs/spnego.service.keytab'
        destination: "#{oozie.site['oozie.authentication.kerberos.keytab']}"
        uid: oozie.user.name
        gid: oozie.group.name
        mode: 0o0600
      .then next

    module.exports.push name: 'Oozie Server # MySQL', handler: (ctx, next) ->
      {db_admin, oozie} = ctx.config.ryba
      username = oozie.site['oozie.service.JPAService.jdbc.username']
      password = oozie.site['oozie.service.JPAService.jdbc.password']
      {engine, db} = parse_jdbc oozie.site['oozie.service.JPAService.jdbc.url']
      engines =
        mysql: ->
          escape = (text) -> text.replace(/[\\"]/g, "\\$&")
          cmd = "#{db_admin.path} -u#{db_admin.username} -p#{db_admin.password} -h#{db_admin.host} -P#{db_admin.port} -e "
          version_local = "#{cmd} \"use #{db}; select data from OOZIE_SYS where name='oozie.version'\" | tail -1"
          version_remote = "ls /usr/hdp/current/oozie-server/lib/oozie-client-*.jar | sed 's/.*client\\-\\(.*\\).jar/\\1/'"
          ctx.execute [
            cmd: """
            if #{cmd} "use #{db}"; then exit 2; fi
            #{cmd} "
            create database #{db};
            grant all privileges on #{db}.* to '#{username}'@'localhost' identified by '#{password}';
            grant all privileges on #{db}.* to '#{username}'@'%' identified by '#{password}';
            flush privileges;
            "
            """
            code_skipped: 2
          ,
            cmd: "su -l #{oozie.user.name} -c '/usr/hdp/current/oozie-client/bin/ooziedb.sh create -sqlfile /tmp/oozie.sql -run Validate DB Connection'"
            not_if_exec: "#{cmd} \"use #{db}; select data from OOZIE_SYS where name='oozie.version'\""
          ,
            cmd: "su -l #{oozie.user.name} -c '/usr/hdp/current/oozie-server/bin/ooziedb.sh upgrade -run'"
            not_if_exec: "[[ `#{version_local}` == `#{version_remote}` ]]"
          ], next
      return next new Error 'Database engine not supported' unless engines[engine]
      engines[engine]()

    # module.exports.push name: 'Oozie Server # Database', handler: (ctx, next) ->
    #   {oozie} = ctx.config.ryba
    #   ctx.execute
    #     cmd: """
    #     su -l #{oozie.user.name} -c '/usr/hdp/current/oozie-client/bin/ooziedb.sh create -sqlfile oozie.sql -run Validate DB Connection'
    #     """
    #   , (err, executed, stdout, stderr) ->
    #     err = null if err and /DB schema exists/.test stderr
    #     next err, executed

# Share libs

Upload the Oozie sharelibs folder. The location of the ShareLib is specified by
the oozie.service.WorkflowAppService.system.libpath configuration property.
Inside this directory, multiple versions may cooexiste inside "lib_{timestamp}"
directories.

Oozie will automatically clean up old ShareLib "lib_{timestamp}" directories
based on the following rules:

*   After ShareLibService.temp.sharelib.retention.days days (default: 7)
*   Will always keep the latest 2

Internally, the "sharelib create" and "sharelib upgrade" commands are used to
upload the files.

The `oozie admin -shareliblist` command can be used by the final user to list
the ShareLib contents without having to go into HDFS.

    module.exports.push name: 'Oozie Server # Share lib', timeout: 600000, handler: (ctx, next) ->
      {core_site, oozie} = ctx.config.ryba
      ctx
      .execute
        cmd: mkcmd.hdfs ctx, """
        if hdfs dfs -test -d /user/#{oozie.user.name}/share/lib; then
          echo 'Upgrade sharelib'
          su -l oozie -c "/usr/hdp/current/oozie-server/bin/oozie-setup.sh sharelib upgrade -fs #{core_site['fs.defaultFS']} /usr/hdp/current/oozie-client/oozie-sharelib.tar.gz"
        else
          # hdfs dfs -mkdir /user/#{oozie.user.name} || true
          hdfs dfs -mkdir -p /user/#{oozie.user.name}/share/lib || true
          hdfs dfs -chown -R #{oozie.user.name}:#{oozie.group.name} /user/#{oozie.user.name}
          echo 'Create sharelib'
          su -l oozie -c "/usr/hdp/current/oozie-server/bin/oozie-setup.sh sharelib create -fs #{core_site['fs.defaultFS']} /usr/hdp/current/oozie-client/oozie-sharelib.tar.gz"
        fi
        hdfs dfs -chmod -R 755 /user/#{oozie.user.name}
        """
        trap_on_error: true
        not_if_exec: mkcmd.hdfs ctx, """
        version=`ls /usr/hdp/current/oozie-client/lib | grep oozie-client | sed 's/^oozie-client-\\(.*\\)\\.jar$/\\1/g'`
        hdfs dfs -cat /user/oozie/share/lib/*/sharelib.properties | grep build.version | grep $version
        """
      .then next

    module.exports.push name: 'Oozie Server # Hive', handler: (ctx, next) ->
      {oozie} = ctx.config.ryba
      properties = {}
      if falcon_ctxs = ctx.contexts 'ryba/falcon', require('../../falcon').configure
        properties['hive.metastore.execute.setugi'] ?= 'true'
      # Note: hdp2.2 falcon docs mentions "hive-site.xml" but only "hive.xml"
      # exists
      ctx
      .hconfigure
        destination: "#{oozie.conf_dir}/action-conf/hive.xml"
        properties: properties
        merge: true
      .then next

    module.exports.push name: 'Oozie Server # Log4J', handler: (ctx, next) ->
      # Instructions mention updating convertion pattern to the same value as
      # default, skip for now
      {oozie} = ctx.config.ryba
      ctx
      .write
        destination: "#{oozie.conf_dir}/oozie-log4j.properties"
        source: "#{__dirname}/../../resources/oozie/oozie-log4j.properties"
        local_source: true
      .then next

## Dependencies

    url = require 'url'
    path = require 'path'
    mkcmd = require '../../lib/mkcmd'
    parse_jdbc = require '../../lib/parse_jdbc'

