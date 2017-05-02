
# HDFS HttpFS Install

    module.exports = header: 'HDFS HttpFS Install', handler: ->
      {httpfs, realm, core_site} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @call 'ryba/hadoop/hdfs_nn/wait'

## Identities

By default, the package create the following entries:

```bash
cat /etc/passwd | grep httpfs
httpfs:x:495:494:Hadoop HTTPFS:/var/run/hadoop/httpfs:/bin/bash
cat /etc/group | grep httpfs
httpfs:x:494:httpfs
```

      @system.group header: 'Group', httpfs.group
      @system.user header: 'User', httpfs.user

## IPTables

| Service   | Port   | Proto  | Parameter                   |
|-----------|--------|--------|-----------------------------|
| datanode  | 14000  | http   | ryba.httpfs.http_port       |
| datanode  | 14001  | http   | ryba.httpfs.http_admin_port |

The "dfs.datanode.address" default to "50010" in non-secured mode. In non-secured
mode, it must be set to a value below "1024" and default to "1004".

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        if: @config.iptables.action is 'start'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: httpfs.http_port, protocol: 'tcp', state: 'NEW', comment: "HDFS HttpFS" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: httpfs.http_admin_port, protocol: 'tcp', state: 'NEW', comment: "HDFS HttpFS" }
        ]

## Package

      @call header: 'Package', timeout: -1, (options) ->
        @service
          name: 'hadoop-httpfs'
        @hdp_select
          name: 'hadoop-httpfs'
        @service.init
          target: "/etc/init.d/hadoop-httpfs"
          source: "#{__dirname}/../resources/hadoop-httpfs.j2"
          local: true
          context: @config
          mode: 0o0755
        @system.tmpfs
          if_os: name: ['redhat','centos'], version: '7'
          mount: "#{httpfs.pid_dir}"
          uid: httpfs.user.name
          gid: httpfs.group.name
          perm: '0755'

## Kerberos

      @call header: 'Kerberos', timeout: -1, ->
        @system.copy # SPNEGO Keytab
          source: core_site['hadoop.http.authentication.kerberos.keytab']
          target: httpfs.site['httpfs.authentication.kerberos.keytab']
          if: core_site['hadoop.http.authentication.kerberos.keytab'] isnt httpfs.site['httpfs.authentication.kerberos.keytab']
          if_exists: core_site['hadoop.http.authentication.kerberos.keytab']
          uid: httpfs.user.name
          gid: httpfs.group.name
          mode: 0o0600
        @krb5.addprinc krb5, # Service Keytab
          principal: httpfs.site['httpfs.hadoop.authentication.kerberos.principal']
          randkey: true
          keytab: httpfs.site['httpfs.hadoop.authentication.kerberos.keytab']
          uid: httpfs.user.name
          gid: httpfs.group.name
          mode: 0o0600

## Environment

      @call header: 'Environment', ->
        @system.mkdir
          target: "#{httpfs.pid_dir}"
          uid: httpfs.user.name
          gid: httpfs.group.name
          mode: 0o0755
        @system.mkdir
          target: "#{httpfs.log_dir}" #/#{hdfs.user.name}
          uid: httpfs.user.name
          gid: httpfs.group.name
          parent: true
        @system.mkdir
          target: "#{httpfs.tmp_dir}"
          uid: httpfs.user.name
          gid: httpfs.group.name
          mode: 0o0755
        @call header: 'HttpFS Env', ->
          httpfs.catalina_opts += " -D#{k}=#{v}" for k, v of httpfs.catalina.opts
          @file.render
            target: "#{httpfs.conf_dir}/httpfs-env.sh"
            source: "#{__dirname}/../resources/httpfs-env.sh.j2"
            local: true
            context: @config
            uid: httpfs.user.name
            gid: httpfs.group.name
            backup: true
            mode: 0o755
        @file.render
          target: "#{httpfs.conf_dir}/httpfs-log4j.properties"
          source: "#{__dirname}/../resources/httpfs-log4j.properties"
          local: true
          context: @config
          backup: true
        @system.link
          source: '/usr/hdp/current/hadoop-httpfs/webapps'
          target: "#{httpfs.catalina_home}/webapps"
        @system.mkdir # CATALINA_TMPDIR
          target: "#{httpfs.catalina_home}/temp"
          uid: httpfs.user.name
          gid: httpfs.group.name
          mode: 0o0750
        @system.mkdir
          target: "#{httpfs.catalina_home}/work"
          uid: httpfs.user.name
          gid: httpfs.group.name
          mode: 0o0750
        @system.copy # Copie original server.xml for no-SSL environments
          source: "#{httpfs.catalina_home}/conf/server.xml"
          target: "#{httpfs.catalina_home}/conf/nossl-server.xml"
          unless_exists: true
        @system.copy
          source: "#{httpfs.catalina_home}/conf/nossl-server.xml"
          target: "#{httpfs.catalina_home}/conf/server.xml"
          unless: httpfs.env.HTTPFS_SSL_ENABLED is 'true'
        @system.copy
          source: "#{httpfs.catalina_home}/conf/ssl-server.xml"
          target: "#{httpfs.catalina_home}/conf/server.xml"
          if: httpfs.env.HTTPFS_SSL_ENABLED is 'true'

## SSL

      @call header: 'SSL', if: httpfs.env.HTTPFS_SSL_ENABLED is 'true', ->
        {ssl, ssl_server, ssl_client} = @config.ryba
        tmp_location = "/var/tmp/ryba/ssl"
        {httpfs} = @config.ryba
        @file.download
          source: ssl.cacert
          target: "#{tmp_location}/#{path.basename ssl.cacert}"
          mode: 0o0600
        @file.download
          source: ssl.cert
          target: "#{tmp_location}/#{path.basename ssl.cert}"
          mode: 0o0600
        @file.download
          source: ssl.key
          target: "#{tmp_location}/#{path.basename ssl.key}"
          mode: 0o0600
        @java.keystore_add
          keystore: httpfs.env.HTTPFS_SSL_KEYSTORE_FILE
          storepass: httpfs.env.HTTPFS_SSL_KEYSTORE_PASS
          caname: "httpfs_root_ca"
          cacert: "#{tmp_location}/#{path.basename ssl.cacert}"
          key: "#{tmp_location}/#{path.basename ssl.key}"
          cert: "#{tmp_location}/#{path.basename ssl.cert}"
          keypass: ssl_server['ssl.server.keystore.keypassword']
          name: @config.shortname
          uid: httpfs.user.name
          gid: httpfs.group.name
          mode: 0o0640
        @system.remove
          target: "#{tmp_location}/#{path.basename ssl.cacert}"
          shy: true
        @system.remove
          target: "#{tmp_location}/#{path.basename ssl.cert}"
          shy: true
        @system.remove
          target: "#{tmp_location}/#{path.basename ssl.key}"
          shy: true

## Configuration

      @hconfigure
        header: 'Configuration'
        target: "#{httpfs.conf_dir}/httpfs-site.xml"
        properties: httpfs.site
        uid: httpfs.user.name
        gid: httpfs.group.name
        backup: true

## Dependencies

    path = require 'path'
