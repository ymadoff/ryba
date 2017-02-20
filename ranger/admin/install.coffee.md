
# Ranger Admin Install

    module.exports =  header: 'Ranger Admin Install', handler: (options) ->
      {ranger, ssl, realm} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## Register

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register 'hconfigure', 'ryba/lib/hconfigure'

## Users & Groups

      @system.group ranger.group
      @system.user ranger.user

## Package

Install the Ranger Policy Manager package and set it to the latest version. Note, we
select the "kafka-broker" hdp directory. There is no "kafka-consumer"
directories.

      @call header: 'Packages', handler: ->
        @service.install
          name: 'ranger-admin'
        @hdp_select
          name: 'ranger-admin'

## Layout

      @system.mkdir
        target: '/var/run/ranger'
        uid: ranger.user.name
        gid: ranger.user.name
        mode: 0o750

## IPTables

| Service              | Port  | Proto       | Parameter          |
|----------------------|-------|-------------|--------------------|
| Ranger policymanager | 6080  | http        | port               |
| Ranger policymanager | 6182  | https       | port               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'Ranger Admin IPTables'
        if: @config.iptables.action is 'start'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: ranger.admin.site['ranger.service.http.port'], protocol: 'tcp', state: 'NEW', comment: "Ranger Admin HTTP WEBUI" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: ranger.admin.site['ranger.service.https.port'], protocol: 'tcp', state: 'NEW', comment: "Ranger Admin HTTPS WEBUI" }
        ]

## Ranger Admin Driver

      @link
        header: 'DB Driver'
        source: '/usr/share/java/mysql-connector-java.jar'
        target: ranger.admin.install['SQL_CONNECTOR_JAR']

## Ranger Databases

      @call header: 'DB Setup',  handler:  ->
        {db_admin} = @config.ryba
        switch ranger.admin.install['DB_FLAVOR'].toLowerCase()
          when 'mysql'
            mysql_exec = "mysql -u#{db_admin.mysql.admin_username} -p#{db_admin.mysql.admin_password} -h#{db_admin.mysql.host} -P#{db_admin.mysql.port} "
            @execute
              cmd: """
              #{mysql_exec} -e "
              SET GLOBAL log_bin_trust_function_creators = 1;
              create database  #{ranger.admin.install['db_name']};
              grant all privileges on #{ranger.admin.install['db_name']}.* to #{ranger.admin.install['db_user']}@'localhost' identified by '#{ranger.admin.install['db_password']}';
              grant all privileges on #{ranger.admin.install['db_name']}.* to #{ranger.admin.install['db_user']}@'%' identified by '#{ranger.admin.install['db_password']}';
              flush privileges;
              "
              """
              unless_exec: "#{mysql_exec} -e 'use #{ranger.admin.install['db_name']}'"
            @execute
              cmd: """
              #{mysql_exec} -e "
              create database  #{ranger.admin.install['audit_db_name']};
              grant all privileges on #{ranger.admin.install['audit_db_name']}.* to #{ranger.admin.install['audit_db_user']}@'localhost' identified by '#{ranger.admin.install['audit_db_password']}';
              grant all privileges on #{ranger.admin.install['audit_db_name']}.* to #{ranger.admin.install['audit_db_user']}@'%' identified by '#{ranger.admin.install['audit_db_password']}';
              flush privileges;
              "
              """
              unless_exec: "#{mysql_exec} -e 'use #{ranger.admin.install['audit_db_name']}'"

## Install Scripts

Update the file "install.properties" with the properties defined by the
"ryba.ranger.admin.install" configuration.

      @render
        header: 'Setup Scripts'
        source: "#{__dirname}/../resources/admin-install.properties.j2"
        target: '/usr/hdp/current/ranger-admin/install.properties'
        local: true
        eof: true
        backup: true
        write: for k, v of ranger.admin.install
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true

## Setup Ranger Admin 
Follow [the instructions][instruction-24-25] for upgrade.
Sometime you can fall on this error on mysql databse.
This function has none of DETERMINISTIC, NO SQL, or READS SQL DATA in its declaration 
and binary logging is enabled.
To pass the setup script you have to set log_bin_trust_function_creators variable to 1
to allow user to create none-determisitic functions.

      @execute
        header: 'Setup Execution'
        shy: true
        cmd: """
          cd /usr/hdp/current/ranger-admin/
          ./setup.sh
        """
      @execute
        header: 'Fix Setup Execution'
        cmd: "chown -R #{ranger.user.name}:#{ranger.user.name} #{ranger.admin.conf_dir}"
      # the setup scripts already render an init.d script but it does not respect 
      # the convention exit code 3 when service is stopped on the status code
      @service.init
        target: '/etc/init.d/ranger-admin'
        source: "#{__dirname}/../resources/ranger-admin"
        local: true
        mode: 0o0755
        context: @config.ryba
      @system.tmpfs
        if: -> (options.store['mecano:system:type'] in ['redhat','centos']) and (options.store['mecano:system:release'][0] is '7')
        mount: '/var/run/ranger'
        uid: ranger.user.name
        gid: ranger.user.name
        perm: '0750'
      @service
        name: 'ranger-admin'
        startup: true

## SSL

      @call
        header: 'Configure SSL'
        if: (ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true')
        handler: ->
          @java_keystore_add
            header: 'SSL'
            keystore: ranger.admin.site['ranger.service.https.attrib.keystore.file']
            storepass: ranger.admin.site['ranger.service.https.attrib.keystore.pass']
            caname: "hadoop_root_ca"
            cacert: "#{ssl.cacert}"
            key: "#{ssl.key}"
            cert: "#{ssl.cert}"
            keypass: 'ryba123'
            name: ranger.admin.site['ranger.service.https.attrib.keystore.keyalias']
            local: true
          @java_keystore_add
            keystore: ranger.admin.site['ranger.service.https.attrib.keystore.file']
            storepass: ranger.admin.site['ranger.service.https.attrib.keystore.pass']
            caname: "hadoop_root_ca"
            cacert: "#{ssl.cacert}"
            local: true
          @java_keystore_add
            keystore: '/usr/java/latest/jre/lib/security/cacerts'
            storepass: 'changeit'
            caname: "hadoop_root_ca"
            cacert: "#{ssl.cacert}"
            local: true
          @hconfigure
            header: 'Admin site'
            target: '/etc/ranger/admin/conf/ranger-admin-site.xml'
            properties: ranger.admin.site
            merge: true
            backup: true

## Ranger Admin Principal

      @krb5_addprinc krb5,
        if: ranger.plugins.principal
        header: 'Ranger Repositories principal'
        principal: ranger.plugins.principal
        randkey: true
        password: ranger.plugins.password
      @krb5_addprinc krb5,
        header: 'Ranger Web UI'
        principal: ranger.admin.install['admin_principal']
        randkey: true
        keytab: ranger.admin.install['admin_keytab']
        uid: ranger.user.name
        gid: ranger.user.name
        mode: 0o600
      @krb5_addprinc krb5,
        header: 'Ranger Web UI'
        principal: ranger.admin.install['lookup_principal']
        randkey: true
        keytab: ranger.admin.install['lookup_keytab']
        uid: ranger.user.name
        gid: ranger.user.name
        mode: 0o600

## Java env
This part of the setup is not documented. Deduce from launch scripts.
      
      @call header: 'Ranger Admin Env', ->
        writes = [
          match: RegExp "JAVA_OPTS=.*", 'm'
          replace: "JAVA_OPTS=\"${JAVA_OPTS} -XX:MaxPermSize=256m -Xmx#{ranger.admin.heap_size} -Xms#{ranger.admin.heap_size} \""
          append: true
        ,

          match: RegExp "export CLASSPATH=.*", 'mg'
          replace: "export CLASSPATH=\"$CLASSPATH:/etc/hadoop/conf:/etc/hbase/conf:/etc/hive/conf\" Ryba Fix conf resources"
          append:true

        ]
        for k,v of ranger.admin.opts
          writes.push
            match: RegExp "^JAVA_OPTS=.*#{k}", 'm'
            replace: "JAVA_OPTS=\"${JAVA_OPTS} -D#{k}=#{v}\" # RYBA, DONT OVERWRITE"
            append: true
        @file
          target: '/etc/ranger/admin/conf/ranger-admin-env-1.sh'
          write: writes
          backup: true
          mode: 0o750
          uid: ranger.user.name
          gid: ranger.group.name

## Log4j

      @file.properties
        target: '/etc/ranger/admin/conf/log4j.properties'
        header: 'ranger Log4properties'
        content: ranger.admin.log4j

      @service.restart
        name: 'ranger-admin'
        if: -> @status()

## Dependencies

    glob = require 'glob'
    path = require 'path'
    quote = require 'regexp-quote'

[instruction-24-25]:http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.5.0/bk_command-line-upgrade/content/upgrade-ranger_24.html
