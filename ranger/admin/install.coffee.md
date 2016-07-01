
# Ranger Admin Install

    module.exports =  header: 'Ranger Admin Install', handler: ->
      {ranger, ssl, realm} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## Register

      @register 'hdp_select', 'ryba/lib/hdp_select'   
      @register 'hconfigure', 'ryba/lib/hconfigure'

## Dependencies
      
      @call once: true, 'masson/core/iptables'
      @call once: true, 'masson/core/krb5_client'
      @call once: true, 'masson/commons/mysql_client'
      @call once: true, 'masson/commons/java'
  
## Users & Groups
      
      @group ranger.group
      @user ranger.user

## Package

Install the Ranger Policy Manager package and set it to the latest version. Note, we
select the "kafka-broker" hdp directory. There is no "kafka-consumer"
directories.

      @call header: 'Packages', handler: ->
        @service
          name: 'ranger-admin'
        @hdp_select
          name: 'ranger-admin'

## IPTables

| Service              | Port  | Proto       | Parameter          |
|----------------------|-------|-------------|--------------------|
| Ranger policymanager | 6080  | http        | port               |
| Ranger policymanager | 6182  | https       | port               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @iptables
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
        destination: ranger.admin.install['SQL_CONNECTOR_JAR']

## Ranger Databases

      @call header: 'DB Setup',  handler:  ->
        {db_admin} = @config.ryba
        mysql_exec = "#{db_admin.path} -u#{db_admin.username} -p#{db_admin.password} -h#{db_admin.host} -P#{db_admin.port} "
        @execute
          cmd: """
          #{mysql_exec} -e "
          create database  ranger;
          grant all privileges on ranger.* to rangeradmin@'localhost' identified by 'rangeradmin123';
          grant all privileges on ranger.* to rangeradmin@'%' identified by 'rangeradmin123';
          flush privileges;
          "
          """
          unless_exec: "#{mysql_exec} -e 'use ranger'"
        @execute
          cmd: """
          #{mysql_exec} -e "
          create database  ranger_audit;
          grant all privileges on ranger_audit.* to rangerlogger@'localhost' identified by 'rangerlogger123';
          grant all privileges on ranger_audit.* to rangerlogger@'%' identified by 'rangerlogger123';
          flush privileges;
          "
          """
          unless_exec: "#{mysql_exec} -e 'use ranger_audit'"


## Install Scripts

Update the file "install.properties" with the properties defined by the
"ryba.ranger.admin.install" configuration.

      @render
        header: 'Setup Scripts'
        source: "#{__dirname}/../resources/admin-install.properties.j2"
        destination: '/usr/hdp/current/ranger-admin/install.properties'
        local_source: true
        eof: true
        backup: true
        write: for k, v of ranger.admin.install
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true

## Setup

      @execute
        header: 'Setup Execution'
        shy: true
        cmd: """
          cd /usr/hdp/current/ranger-admin/
          ./setup.sh
        """
      
      # the setup scripts already render an init.d script but it does not respect 
      # the convention exit code 3 when service is stopped on the status code
      @render
        destination: '/etc/init.d/ranger-admin'
        source: "#{__dirname}/../resources/ranger-admin"
        local_source: true
        mode: 0o0755
        context: @config.ryba
        unlink: true
      
    
      @call
        header: 'Configure SSL'
        if: (ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true')
        handler: ->
          @java_keystore_add
            header: 'SSL'
            keystore: ranger.admin.site['ranger.https.attrib.keystore.file']
            storepass: ranger.admin.site['ranger.service.https.attrib.keystore.pass']
            caname: "hadoop_root_ca"
            cacert: "#{ssl.cacert}"
            key: "#{ssl.key}"
            cert: "#{ssl.cert}"
            keypass: 'ryba123'
            name: ranger.admin.site['ranger.service.https.attrib.keystore.keyalias']
            local_source: true
          @java_keystore_add
            keystore: ranger.admin.site['ranger.https.attrib.keystore.file']
            storepass: ranger.admin.site['ranger.service.https.attrib.keystore.pass']
            caname: "hadoop_root_ca"
            cacert: "#{ssl.cacert}"
            local_source: true
          @java_keystore_add
            keystore: '/usr/java/latest/jre/lib/security/cacerts'
            storepass: 'changeit'
            caname: "hadoop_root_ca"
            cacert: "#{ssl.cacert}"
            local_source: true
          @hconfigure
            header: 'Admin site'
            destination: '/etc/ranger/admin/conf/ranger-admin-site.xml'
            properties: ranger.admin.site
            merge: true
            backup: true

## Ranger Plugins principal

      @krb5_addprinc krb5,
        if: ranger.plugins.principal
        header: 'Ranger Repositories principal'
        principal: ranger.plugins.principal
        randkey: true
        password: ranger.plugins.password

## Java env
This part of the setup is not documented. Deduce from launch scripts.
      
      writes = [
        match: RegExp "JAVA_OPTS=.*", 'm'
        replace: "JAVA_OPTS=\"${JAVA_OPTS} -XX:MaxPermSize=256m -Xmx#{ranger.admin.heap_size} -Xms#{ranger.admin.heap_size} \""
        append: true
      ]
      for k,v of ranger.admin.opts
        writes.push
          match: RegExp "^JAVA_OPTS=.*#{k}", 'm'
          replace: "JAVA_OPTS=\"${JAVA_OPTS} -D#{k}=#{v}\" # RYBA, DONT OVERWRITE"
          append: true
      @write
        header: 'Admin Env'
        destination: '/etc/ranger/admin/conf/ranger-admin-env-1.sh'
        write: writes
        backup: true      

## Dependencies

    glob = require 'glob'
    path = require 'path'
    quote = require 'regexp-quote'
