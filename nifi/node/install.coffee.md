
# NiFi Node Install

    module.exports = header: 'NiFi Node Install', handler: ->
      {nifi, hadoop_group} = @config.ryba
      {ssl, ssl_server, ssl_client, hadoop_conf_dir, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      {java} = @config
      tmp_ssl_location = "/var/tmp/ryba/ssl"
      tmp_archive_location = "/var/tmp/ryba/nifi.tar.gz"
      protocol = if nifi.node.config.properties['nifi.cluster.protocol.is.secure'] is 'true' then 'https' else 'http'

# Users

      @group nifi.group
      @user nifi.user

# IPTables

  | Service    | Port  | Proto  | Parameter                                   |
  |------------|-------|--------|---------------------------------------------|
  | node       | 9850  | tcp    | nifi.web.http.port                          |
  | node       | 9860  | tcp    | nifi.web.https.port                         |
  
      @iptables
        header: 'IPTables'
        if: @config.iptables.action is 'start'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: nifi.node.config.properties["nifi.web.#{protocol}.port"], protocol: 'tcp', state: 'NEW', comment: "NiFi Web ui port" }
        ]
    
      @call header: 'Preinstall Layout', handler: ->
          @mkdir
            destination: nifi.node.install_dir
          @mkdir
            destination: nifi.node.conf_dir
          @mkdir
            destination: nifi.node.log_dir
            uid: nifi.user.name
            gid: nifi.group.name

      @call 
        header: 'Packages'
        timeout:-1
        unless_exec: "grep 'nifi.version=#{nifi.version}' #{nifi.node.install_dir}/#{nifi.version}/conf/nifi.properties"
        handler: ->
          @mkdir
            destination: "#{nifi.node.install_dir}/#{nifi.version}"
          @download
            source: nifi.source
            destination: tmp_archive_location
          @extract
            source: tmp_archive_location
            destination: "#{nifi.node.install_dir}/#{nifi.version}"
            preserve_owner: false
            strip: 1
          @remove
            destination: tmp_archive_location

      @call
        header: 'Postinstall Layout'
        timeout:-1
        handler: ->
          @link
            source: "#{nifi.node.install_dir}/#{nifi.version}"
            destination: "#{nifi.node.install_dir}/current"
          # set current version to downloaded version (to support upgrades)
          @remove 
            destination: "#{nifi.node.install_dir}/current/conf"
            if_exec: "test -d #{nifi.node.install_dir}/current/conf"
          @link
            source: nifi.node.conf_dir
            destination: "#{nifi.node.install_dir}/current/conf"
          @remove 
            destination: "#{nifi.node.install_dir}/current/logs"
          # needs to have read/write privileges to load Nar bundles
          @execute
            cmd: "chmod 777 -R #{nifi.node.install_dir}/current/lib"
          @render
            source: "#{__dirname}/resources/nifi-node.j2"
            destination: '/etc/init.d/nifi-node'
            local_source: true
            context: @config
            mode: 0o0755
          # https://github.com/apache/nifi/blob/master/nifi-bootstrap/src/main/java/org/apache/nifi/bootstrap/RunNiFi.java#L335
          # enable nifi to create pid file in nifi.home/bin directory
          @chown
            destination: "#{nifi.node.install_dir}/current/bin"
            uid: nifi.user.name
            gid: nifi.group.name

# Notifications

      @download
        header: 'Services Notifications'
        destination: "#{nifi.node.conf_dir}/bootstrap-notification-services.xml"
        source: "#{__dirname}/../resources/bootstrap-notification-services.xml"

# Log Configuration

      @render
        header: 'Log Configuration'
        destination: "#{nifi.node.conf_dir}/logback.xml"
        source: "#{__dirname}/../resources/logback.xml.j2"
        local_source: true
        context: nifi.node

## Cluster Manager authority provider

      @render
        header: 'Authority Providers'
        destination: "#{nifi.node.conf_dir}/authority-providers.xml"
        source: "#{__dirname}/../resources/authority-providers.xml.j2"
        local_source: true
        context: nifi.node
        uid: nifi.user.name
        gid: nifi.group.name
        backup: true
        eof: true
        mode: 0o0755

## Cluster State Provider

Describes where the NiFi server store its internal states.
By default it is a local file, but in cluster mode, it uses zookeeper.

      @render
        header: 'State Provider'
        source: "#{__dirname}/../resources/state-management.xml.j2"
        destination: "#{nifi.node.conf_dir}/state-management.xml"
        context: @config.ryba
        local_source: true
        uid: nifi.user.name
        gid: nifi.group.name
        backup: true
        mode: 0o0755

      @krb5_addprinc
        header: 'Kerberos'
        principal: nifi.node.krb5_principal
        randkey: true
        keytab: nifi.node.krb5_keytab
        uid: nifi.user.name
        gid: nifi.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

## Zookeeper JAAS  

      @write_jaas
        header: 'Zookeeper JAAS'
        destination: "#{nifi.node.conf_dir}/nifi-zookeeper.jaas"
        content: Client:
          principal: nifi.node.krb5_principal
          keyTab: nifi.node.krb5_keytab
        uid: nifi.user.name
        gid: nifi.group.name
        mode: 0o700
      @render
        header: 'Bootstrap Conf'
        source: "#{__dirname}/../resources/bootstrap.conf.j2"
        destination: "#{nifi.node.conf_dir}/bootstrap.conf"
        eof: true
        backup: true
        context:
          java_opts: nifi.node.java_opts
          user: nifi.user
          conf_dir: nifi.node.conf_dir
          install_dir: nifi.node.install_dir
        local_source: true

## Configuration  

      @render
        header: 'Server properties'
        source: "#{__dirname}/../resources/nifi.properties"
        destination: "#{nifi.node.conf_dir}/nifi.properties"
        local_source: true
        write: for k, v of nifi.node.config.properties
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true

      @call header: 'SSL', retry: 0, handler: ->
        # Client: import certificate to all hosts
        @java_keystore_add
          keystore: nifi.node.config.properties['nifi.security.truststore']
          storepass: nifi.node.config.properties['nifi.security.truststorePasswd']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          local_source: true
        # Server: import certificates, private and public keys to hosts with a server
        @java_keystore_add
          keystore: nifi.node.config.properties['nifi.security.keystore']
          storepass: nifi.node.config.properties['nifi.security.keystorePasswd']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          key: "#{ssl.key}"
          cert: "#{ssl.cert}"
          keypass: nifi.node.config.properties['nifi.security.keyPasswd']
          name: @config.shortname
          local_source: true
        @java_keystore_add
          keystore: nifi.node.config.properties['nifi.security.keystore']
          storepass: nifi.node.config.properties['nifi.security.keystorePasswd']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          local_source: true

## Additional Libs

      @call header: 'Additional Libs', handler: ->
        for lib in nifi.node.additional_libs
          @download
            source: lib
            destination: "#{nifi.node.install_dir}/current/lib/extras/#{path.basename lib}"
            mode: 0o644

# User limits

      @system_limits
        user: nifi.user.name
        nofile: nifi.user.limits.nofile
        nproc: nifi.user.limits.nproc

## Dependencies

    glob = require 'glob'
    path = require 'path'
    quote = require 'regexp-quote'
