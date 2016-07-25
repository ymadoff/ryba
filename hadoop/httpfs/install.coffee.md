
# HDFS HttpFS Install

    module.exports = header: 'HDFS HttpFS Install', handler: ->
      {httpfs, realm, core_site} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## Register

      @register 'hconfigure', 'ryba/lib/hconfigure'
      @register 'hdp_select', 'ryba/lib/hdp_select'
      @call 'ryba/hadoop/hdfs_nn/wait'

## Users & Groups

By default, the package create the following entries:

```bash
cat /etc/passwd | grep httpfs
httpfs:x:495:494:Hadoop HTTPFS:/var/run/hadoop/httpfs:/bin/bash
cat /etc/group | grep httpfs
httpfs:x:494:httpfs
```

      @call header: 'Users & Groups', handler: ->
        {httpfs} = @config.ryba
        @group httpfs.group
        @user httpfs.user

## IPTables

| Service   | Port   | Proto  | Parameter                   |
|-----------|--------|--------|-----------------------------|
| datanode  | 14000  | http   | ryba.httpfs.http_port       |
| datanode  | 14001  | http   | ryba.httpfs.http_admin_port |

The "dfs.datanode.address" default to "50010" in non-secured mode. In non-secured
mode, it must be set to a value below "1024" and default to "1004".

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @iptables
        header: 'IPTables'
        if: @config.iptables.action is 'start'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: httpfs.http_port, protocol: 'tcp', state: 'NEW', comment: "HDFS HttpFS" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: httpfs.http_admin_port, protocol: 'tcp', state: 'NEW', comment: "HDFS HttpFS" }
        ]

## Package

      @call header: 'Package', timeout: -1, handler: ->
        @service
          name: 'hadoop-httpfs'
        @hdp_select
          name: 'hadoop-httpfs'
        @render
          destination: "/etc/init.d/hadoop-httpfs"
          source: "#{__dirname}/../resources/hadoop-httpfs"
          local_source: true
          context: @config
          mode: 0o0755

## Kerberos

      @call header: 'Kerberos', timeout: -1, handler: ->
        @copy # SPNEGO Keytab
          source: core_site['hadoop.http.authentication.kerberos.keytab']
          destination: httpfs.site['httpfs.authentication.kerberos.keytab']
          if: core_site['hadoop.http.authentication.kerberos.keytab'] isnt httpfs.site['httpfs.authentication.kerberos.keytab']
          if_exists: core_site['hadoop.http.authentication.kerberos.keytab']
          uid: httpfs.user.name
          gid: httpfs.group.name
          mode: 0o0600
        @krb5_addprinc krb5, # Service Keytab
          principal: httpfs.site['httpfs.hadoop.authentication.kerberos.principal']
          randkey: true
          keytab: httpfs.site['httpfs.hadoop.authentication.kerberos.keytab']
          uid: httpfs.user.name
          gid: httpfs.group.name
          mode: 0o0600

## Environment

      @call header: 'Environment', handler: ->
        @mkdir
          destination: "#{httpfs.pid_dir}"
          uid: httpfs.user.name
          gid: httpfs.group.name
          mode: 0o0755
        @mkdir
          destination: "#{httpfs.tmp_dir}"
          uid: httpfs.user.name
          gid: httpfs.group.name
          mode: 0o0755
        @mkdir
          destination: "#{httpfs.log_dir}" #/#{hdfs.user.name}
          uid: httpfs.user.name
          gid: httpfs.group.name
          parent: true
        @call header: 'HttpFS Env', handler: ->
          httpfs.catalina_opts += " -D#{k}=#{v}" for k, v of httpfs.catalina.opts
          @render
            destination: "#{httpfs.conf_dir}/httpfs-env.sh"
            source: "#{__dirname}/../resources/httpfs-env.sh.j2"
            local_source: true
            context: @config
            uid: httpfs.user.name
            gid: httpfs.group.name
            backup: true
        @render
          destination: "#{httpfs.conf_dir}/httpfs-log4j.properties"
          source: "#{__dirname}/../resources/httpfs-log4j.properties"
          local_source: true
          context: @config
          backup: true
        @link
          source: '/usr/hdp/current/hadoop-httpfs/webapps'
          destination: "#{httpfs.catalina_home}/webapps"
        @mkdir # CATALINA_TMPDIR
          destination: "#{httpfs.catalina_home}/temp"
          uid: httpfs.user.name
          gid: httpfs.group.name
          mode: 0o0750
        @mkdir
          destination: "#{httpfs.catalina_home}/work"
          uid: httpfs.user.name
          gid: httpfs.group.name
          mode: 0o0750
        @copy # Copie original server.xml for no-SSL environments
          source: "#{httpfs.catalina_home}/conf/server.xml"
          destination: "#{httpfs.catalina_home}/conf/nossl-server.xml"
          unless_exists: true
        @copy
          source: "#{httpfs.catalina_home}/conf/nossl-server.xml"
          destination: "#{httpfs.catalina_home}/conf/server.xml"
          unless: httpfs.env.HTTPFS_SSL_ENABLED is 'true'
        @copy
          source: "#{httpfs.catalina_home}/conf/ssl-server.xml"
          destination: "#{httpfs.catalina_home}/conf/server.xml"
          if: httpfs.env.HTTPFS_SSL_ENABLED is 'true'

## SSL

      @call header: 'SSL', if: httpfs.env.HTTPFS_SSL_ENABLED is 'true', handler: ->
        {ssl, ssl_server, ssl_client} = @config.ryba
        tmp_location = "/var/tmp/ryba/ssl"
        {httpfs} = @config.ryba
        @download
          source: ssl.cacert
          destination: "#{tmp_location}/#{path.basename ssl.cacert}"
          mode: 0o0600
        @download
          source: ssl.cert
          destination: "#{tmp_location}/#{path.basename ssl.cert}"
          mode: 0o0600
        @download
          source: ssl.key
          destination: "#{tmp_location}/#{path.basename ssl.key}"
          mode: 0o0600
        @java_keystore_add
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
        @remove
          destination: "#{tmp_location}/#{path.basename ssl.cacert}"
          shy: true
        @remove
          destination: "#{tmp_location}/#{path.basename ssl.cert}"
          shy: true
        @remove
          destination: "#{tmp_location}/#{path.basename ssl.key}"
          shy: true

## Configuration

      @hconfigure
        header: 'Configuration'
        destination: "#{httpfs.conf_dir}/httpfs-site.xml"
        properties: httpfs.site
        uid: httpfs.user.name
        gid: httpfs.group.name
        backup: true

## Dependencies

    path = require 'path'
