
# Oozie Server Install

Oozie source code and examples are located in "/usr/share/doc/oozie-$version".

The current version of Oozie doesnt supported automatic failover of the Yarn
Resource Manager. RM HA (High Availability) must be configure with manual
failover and Oozie must target the active node.

    module.exports = header: 'Oozie Server Install', handler: ->
      {oozie, hadoop_group, hadoop_conf_dir, yarn, realm, db_admin, core_site, ssl_client,ssl} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      is_falcon_installed = @contexts('ryba/falcon').length isnt 0
      port = url.parse(oozie.site['oozie.base.url']).port

## Register

      @register 'hconfigure', 'ryba/lib/hconfigure'
      @register 'hdp_select', 'ryba/lib/hdp_select'
      @register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'

## Users & Groups

By default, the "oozie" package create the following entries:

```bash
cat /etc/passwd | grep oozie
oozie:x:493:493:Oozie User:/var/lib/oozie:/bin/bash
cat /etc/group | grep oozie
oozie:x:493:
```

      @group oozie.group
      @user oozie.user

## IPTables

| Service | Port  | Proto | Info                      |
|---------|-------|-------|---------------------------|
| oozie   | 11443 | http  | Oozie HTTP secure server  |
| oozie   | 11001 | http  | Oozie Admin server        |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'tcp', state: 'NEW', comment: "Oozie HTTP Server" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: oozie.admin_port, protocol: 'tcp', state: 'NEW', comment: "Oozie HTTP Server" }
        ]
        if: @config.iptables.action is 'start'

    
      @call header: 'Packages', timeout: -1, handler: ->
        # Upgrading oozie failed, tested versions are hdp 2.1.2 -> 2.1.5 -> 2.1.7
        @execute
          cmd: "rm -rf /usr/lib/oozie && yum remove -y oozie oozie-client"
          if: @retry > 0
        @service
          name: 'falcon'
          if: is_falcon_installed
        @service
          name: 'unzip' # Required by the "prepare-war" command
        @service
          name: 'zip' # Required by the "prepare-war" command
        @service
          name: 'extjs-2.2-1'
        # @call if: @contexts('ryba/falcon').length, ->
        #   @service
        #     name: 'falcon'
        #   @hdp_select
        #     name: 'falcon-client'
        @service
          name: 'falcon'
          if: @contexts('ryba/falcon').length
        @hdp_select
          name: 'falcon-client'
          if: @contexts('ryba/falcon').length
        @service
          name: 'oozie' # Also install oozie-client and bigtop-tomcat
        @hdp_select
          name: 'oozie-server'
        @hdp_select
          name: 'oozie-client'
        @write
          header: 'Init Script'
          source: "#{__dirname}/../resources/oozie"
          local_source: true
          destination: '/etc/init.d/oozie'
          mode: 0o0755
          unlink: true
        @execute
          cmd: "service oozie restart"
          if: -> @status -4

      @call header: 'Layout Directories', handler: ->
        @mkdir
          destination: oozie.data
          uid: oozie.user.name
          gid: hadoop_group.name
          mode: 0o0755
        @mkdir
          destination: oozie.log_dir
          uid: oozie.user.name
          gid: hadoop_group.name
          mode: 0o0755
        @mkdir
          destination: oozie.pid_dir
          uid: oozie.user.name
          gid: hadoop_group.name
          mode: 0o0755
        @mkdir
          destination: oozie.tmp_dir
          uid: oozie.user.name
          gid: hadoop_group.name
          mode: 0o0755
        @mkdir
          destination: "#{oozie.conf_dir}/action-conf"
          uid: oozie.user.name
          gid: hadoop_group.name
          mode: 0o0755
        # Set permission to action conf
        @execute
          cmd: """
          chown -R #{oozie.user.name}:#{hadoop_group.name} #{oozie.conf_dir}/action-conf
          """
          shy: true
        # Waiting for recursivity in @mkdir
        # @execute
        #   cmd: """
        #   chown -R #{oozie.user.name}:#{hadoop_group.name} /usr/lib/oozie
        #   chown -R #{oozie.user.name}:#{hadoop_group.name} #{oozie.data}
        #   chown -R #{oozie.user.name}:#{hadoop_group.name} #{oozie.conf_dir} #/..
        #   chmod -R 755 #{oozie.conf_dir} #/..
        #   """

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

      writes = [
          match: /^export OOZIE_HTTPS_KEYSTORE_FILE=.*$/mg
          replace: "export OOZIE_HTTPS_KEYSTORE_FILE=#{oozie.keystore_file}"
          append: true
        ,
          match: /^export OOZIE_HTTPS_KEYSTORE_PASS=.*$/mg
          replace: "export OOZIE_HTTPS_KEYSTORE_PASS=#{oozie.keystore_pass}"
          append: true
        ,
          match: /^export CATALINA_OPTS="${CATALINA_OPTS} -Djavax.net.ssl.trustStore=(.*)/m
          replace: """
          export CATALINA_OPTS="${CATALINA_OPTS} -Djavax.net.ssl.trustStore=#{oozie.truststore_file}"
          """
          append: true
        ,
          match: /^export CATALINA_OPTS="${CATALINA_OPTS} -Djavax.net.ssl.trustStorePassword=(.*)/m
          replace: """
          export CATALINA_OPTS="${CATALINA_OPTS} -Djavax.net.ssl.trustStorePassword=#{oozie.truststore_pass}"
          """
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
        header: 'Oozie Environment'
        destination: "#{oozie.conf_dir}/oozie-env.sh"
        source: "#{__dirname}/../resources/oozie-env.sh.j2"
        local_source: true
        context: @config
        write: writes
        uid: oozie.user.name
        gid: oozie.group.name
        mode: 0o0755
        backup: true

# ExtJS

Install the ExtJS Javascript library as part of enabling the Oozie Web Console.

      @copy
        header: 'ExtJS Library'
        source: '/usr/share/HDP-oozie/ext-2.2.zip'
        destination: '/usr/hdp/current/oozie-client/libext/'

# HBase credentials

Install the HBase Libs as part of enabling the Oozie Unified Credentials with HBase.

      @copy
        header: 'HBase Libs'
        source: '/usr/hdp/current/hbase-client/lib/hbase-common.jar'
        destination: '/usr/hdp/current/oozie-client/libserver/'

# LZO

Install the LZO compression library as part of enabling the Oozie Web Console.

      @call header: 'LZO', handler: ->
        lzo_jar = null
        @execute
          cmd: 'ls /usr/hdp/current/share/lzo/*/lib/hadoop-lzo-*.jar'
        , (err, _, stdout) ->
          return if err
          lzo_jar = stdout.trim()
        @call ->
          @execute
            cmd: """
            # Remove any previously installed version
            rm /usr/hdp/current/oozie-client/libext/hadoop-lzo-*.jar
            # Copy lzo
            cp #{lzo_jar} /usr/hdp/current/oozie-client/libext/
            """
            unless_exists: "/usr/hdp/current/oozie-client/libext/#{path.basename lzo_jar}"

    # Note
    # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.0/HDP_Man_Install_v22/index.html#Item1.12.4.3
    # Copy or symlink the MySQL JDBC driver JAR into the /var/lib/oozie/ directory.
      @link
        header: 'Mysql Driver'
        source: '/usr/share/java/mysql-connector-java.jar'
        destination: '/usr/hdp/current/oozie-client/libext/mysql-connector-java.jar'

      @call header: 'Configuration', handler: ->
        @hconfigure
          destination: "#{oozie.conf_dir}/oozie-site.xml"
          default: "#{__dirname}/../resources/oozie-site.xml"
          local_default: true
          properties: oozie.site
          uid: oozie.user.name
          gid: oozie.group.name
          mode: 0o0755
          merge: true
          backup: true
        @write
          destination: "#{oozie.conf_dir}/oozie-default.xml"
          source: "#{__dirname}/../resources/oozie-default.xml"
          local_source: true
          backup: true
        @hconfigure
          destination: "#{oozie.conf_dir}/hadoop-conf/core-site.xml"
          local_default: true
          properties: oozie.hadoop_config
          uid: oozie.user.name
          gid: oozie.group.name
          mode: 0o0755
          backup: true

      @call header: 'SSL Server', handler: ->
        @java_keystore_add
          header: 'SSL'
          keystore: oozie.keystore_file
          storepass: oozie.keystore_pass
          caname: 'hadoop_root_ca'
          cacert: "#{ssl.cacert}"
          key: "#{ssl.key}"
          cert: "#{ssl.cert}"
          keypass: oozie.keystore_pass
          name: @config.shortname
          local_source: true
        @java_keystore_add
          keystore: oozie.keystore_file
          storepass: oozie.keystore_pass
          caname: 'hadoop_root_ca'
          cacert: "#{ssl.cacert}"
          local_source: true
        # fix oozie pkix build exceptionm when oozie server connects to hadoop mr
        @java_keystore_add
          keystore: oozie.truststore_file
          storepass: oozie.truststore_pass
          caname: 'hadoop_root_ca'
          cacert: "#{ssl.cacert}"
          local_source: true
      
      @call header: 'War', handler: ->
        @call
          header: 'Falcon Package'
          if: is_falcon_installed
          handler: ->
            @service
              name: 'falcon'
            @mkdir
              destination: '/tmp/falcon-oozie-jars'
            # Note, the documentation mentions using "-d" option but it doesnt
            # seem to work. Instead, we deploy the jar where "-d" default.
            @execute
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
            @execute
              cmd: """
              if [ ! -f #{oozie.pid_dir}/oozie.pid ]; then exit 3; fi
              if ! kill -0 >/dev/null 2>&1 `cat #{oozie.pid_dir}/oozie.pid`; then exit 3; fi
              su -l #{oozie.user.name} -c "/usr/hdp/current/oozie-server/bin/oozied.sh stop 20 -force"
              rm -rf cat #{oozie.pid_dir}/oozie.pid
              """
              code_skipped: 3
      # The script `ooziedb.sh` must be done as the oozie Unix user, otherwise
      # Oozie may fail to start or work properly because of incorrect file permissions.
      # There is already a "oozie.war" file inside /var/lib/oozie/oozie-server/webapps/.
      # The "prepare-war" command generate the file "/var/lib/oozie/oozie-server/webapps/oozie.war".
      # The directory being served by the web server is "prepare-war".
      # See note 20 lines above about "-d" option
      # falcon_opts = if falcon_ctxs.length then " –d /tmp/falcon-oozie-jars" else ''
      secure_opt = if oozie.secure then '-secure' else ''
      falcon_opts = ''
      @execute
        cmd: """
        chown #{oozie.user.name} /usr/hdp/current/oozie-client/oozie-server/conf/server.xml
        su -l #{oozie.user.name} -c 'cd /usr/hdp/current/oozie-client; ./bin/oozie-setup.sh prepare-war #{secure_opt} #{falcon_opts}'
        """
        code_skipped: 255 # Oozie already started, war is expected to be installed

## Kerberos

      @krb5_addprinc krb5,
        header: 'Kerberos'
        principal: oozie.site['oozie.service.HadoopAccessorService.kerberos.principal'] #.replace '_HOST', @config.host
        randkey: true
        keytab: oozie.site['oozie.service.HadoopAccessorService.keytab.file']
        uid: oozie.user.name
        gid: oozie.group.name
      @copy
        header: 'SPNEGO'
        source: '/etc/security/keytabs/spnego.service.keytab'
        destination: "#{oozie.site['oozie.authentication.kerberos.keytab']}"
        uid: oozie.user.name
        gid: oozie.group.name
        mode: 0o0600

## MySQL Database Creation

      @call header: 'MySQL Database Creation', handler: ->
        username = oozie.site['oozie.service.JPAService.jdbc.username']
        password = oozie.site['oozie.service.JPAService.jdbc.password']
        {engine, db} = parse_jdbc oozie.site['oozie.service.JPAService.jdbc.url']
        switch engine
          when 'mysql'
            escape = (text) -> text.replace(/[\\"]/g, "\\$&")
            cmd = "#{db_admin.path} -u#{db_admin.username} -p#{db_admin.password} -h#{db_admin.host} -P#{db_admin.port} -e "
            version_local = "#{cmd} \"use #{db}; select data from OOZIE_SYS where name='oozie.version'\" | tail -1"
            version_remote = "ls /usr/hdp/current/oozie-server/lib/oozie-client-*.jar | sed 's/.*client\\-\\(.*\\).jar/\\1/'"
            @execute
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
            @execute
               cmd: "su -l #{oozie.user.name} -c '/usr/hdp/current/oozie-client/bin/ooziedb.sh create -sqlfile /tmp/oozie.sql -run Validate DB Connection'"
               unless_exec: "#{cmd} \"use #{db}; select data from OOZIE_SYS where name='oozie.version'\""
            @execute
               cmd: "su -l #{oozie.user.name} -c '/usr/hdp/current/oozie-server/bin/ooziedb.sh upgrade -run'"
               unless_exec: "[[ `#{version_local}` == `#{version_remote}` ]]"
          else throw Error 'Database engine not supported'

    # module.exports.push header: 'Oozie Server # Database', handler: ->
    #   {oozie} = @config.ryba
    #   @execute
    #     cmd: """
    #     su -l #{oozie.user.name} -c '/usr/hdp/current/oozie-client/bin/ooziedb.sh create -sqlfile oozie.sql -run Validate DB Connection'
    #     """
    #   , (err, executed, stdout, stderr) ->
    #     err = null if err and /DB schema exists/.test stderr

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

      @call once: true, 'ryba/hadoop/hdfs_nn/wait'
      @call header: 'Share lib', timeout: 600000, handler: ->
        @hdfs_mkdir
          destination: "/user/#{oozie.user.name}/share/lib"
          user: "#{oozie.user.name}"
          group:  "#{oozie.group.name}"
          mode: 0o0755
          krb5_user: @config.ryba.hdfs.krb5_user
        @execute
          cmd: mkcmd.hdfs @, """
          if hdfs dfs -test -d /user/#{oozie.user.name}/share/lib; then
            echo 'Upgrade sharelib'
            su -l oozie -c "/usr/hdp/current/oozie-server/bin/oozie-setup.sh sharelib upgrade -fs #{core_site['fs.defaultFS']} /usr/hdp/current/oozie-client/oozie-sharelib.tar.gz"
          else
            #hdfs dfs -mkdir -p /user/#{oozie.user.name}/share/lib || true
            #hdfs dfs -chown -R #{oozie.user.name}:#{oozie.group.name} /user/#{oozie.user.name}
            echo 'Create sharelib'
            su -l oozie -c "/usr/hdp/current/oozie-server/bin/oozie-setup.sh sharelib create -fs #{core_site['fs.defaultFS']} /usr/hdp/current/oozie-client/oozie-sharelib.tar.gz"
          fi
          hdfs dfs -chmod -R 755 /user/#{oozie.user.name}
          """
          trap: true
          unless_exec: mkcmd.hdfs @, """
          version=`ls /usr/hdp/current/oozie-client/lib | grep oozie-client | sed 's/^oozie-client-\\(.*\\)\\.jar$/\\1/g'`
          hdfs dfs -cat /user/oozie/share/lib/*/sharelib.properties | grep build.version | grep $version
          """
## Hive Site

      @hconfigure 
        header: 'Hive Site'
        if: is_falcon_installed
        destination: "#{oozie.conf_dir}/action-conf/hive.xml"
        properties: 'hive.metastore.execute.setugi': 'true'
        merge: true

## Log4J properties

      # Instructions mention updating convertion pattern to the same value as
      # default, skip for now
      #TODO: Declare all properties during configure and use write_properties
      @write
        header: 'Log4J properties'
        destination: "#{oozie.conf_dir}/oozie-log4j.properties"
        source: "#{__dirname}/../resources/oozie-log4j.properties"
        local_source: true
        backup: true
        write: for k, v of oozie.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true

## Dependencies

    url = require 'url'
    path = require 'path'
    mkcmd = require '../../lib/mkcmd'
    parse_jdbc = require '../../lib/parse_jdbc'
    quote = require 'regexp-quote'
