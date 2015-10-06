
# HDFS HttpFS Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdp_select'

## Users & Groups

By default, the package create the following entries:

```bash
cat /etc/passwd | grep httpfs
httpfs:x:495:494:Hadoop HTTPFS:/var/run/hadoop/httpfs:/bin/bash
cat /etc/group | grep httpfs
httpfs:x:494:httpfs
```

    module.exports.push name: 'HDFS HttpFS # Users & Groups', handler: ->
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

    module.exports.push name: 'HDFS HttpFS # IPTables', handler: ->
      {httpfs} = @config.ryba
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: httpfs.http_port, protocol: 'tcp', state: 'NEW', comment: "HDFS HttpFS" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: httpfs.http_admin_port, protocol: 'tcp', state: 'NEW', comment: "HDFS HttpFS" }
        ]
        if: @config.iptables.action is 'start'

## Package

    module.exports.push name: 'HDFS HttpFS # Package', timeout: -1, handler: ->
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

    module.exports.push name: 'HDFS HttpFS # Kerberos', timeout: -1, handler: ->
      {httpfs, realm, core_site} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @copy # SPNEGO Keytab
        source: core_site['hadoop.http.authentication.kerberos.keytab']
        destination: httpfs.site['httpfs.authentication.kerberos.keytab']
        if: core_site['hadoop.http.authentication.kerberos.keytab'] isnt httpfs.site['httpfs.authentication.kerberos.keytab']
        if_exists: core_site['hadoop.http.authentication.kerberos.keytab']
        uid: httpfs.user.name
        gid: httpfs.group.name
        mode: 0o0600
      @krb5_addprinc # Service Keytab
        principal: httpfs.site['httpfs.hadoop.authentication.kerberos.principal']
        randkey: true
        keytab: httpfs.site['httpfs.hadoop.authentication.kerberos.keytab']
        uid: httpfs.user.name
        gid: httpfs.group.name
        mode: 0o0600
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

## Environment

    module.exports.push name: 'HDFS HttpFS # Environment', timeout: -1, handler: ->
      {httpfs} = @config.ryba
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
      @render
        destination: "#{httpfs.conf_dir}/httpfs-env.sh"
        source: "#{__dirname}/../resources/httpfs-env.sh"
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
      

## Configuration

    module.exports.push name: 'HDFS HttpFS # Environment', timeout: -1, handler: ->
      {httpfs} = @config.ryba
      @hconfigure
        destination: "#{httpfs.conf_dir}/httpfs-site.xml"
        properties: httpfs.site
        uid: httpfs.user.name
        gid: httpfs.group.name
        merge: true
        backup: true
