
# HBase Rest Gateway Install

Note, Hortonworks recommand to grant administrative access to the _acl_ table
for the service princial define by "hbase.rest.kerberos.principal". For example,
run the command `grant '$USER', 'RWCA'`. Ryba isnt doing it because we didn't
have usecase for it yet.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/hadoop/core'
    module.exports.push 'ryba/hbase' # Rest server is client to master server
    # module.exports.push require('./index').configure
    module.exports.push 'ryba/lib/hconfigure'
    module.exports.push 'ryba/lib/hdp_select'

## IPTables

| Service                    | Port  | Proto | Info                   |
|----------------------------|-------|-------|------------------------|
| HBase REST Server          | 60080 | http  | hbase.rest.port        |
| HBase REST Server Web UI   | 60085 | http  | hbase.rest.info.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push header: 'HBase Rest # IPTables', handler: ->
      {hbase} = @config.ryba
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.rest.site['hbase.rest.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.rest.site['hbase.rest.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Info Web UI" }
        ]
        if: @config.iptables.action is 'start'


## HBase Rest Server Layout

    module.exports.push header: 'HBase Rest # Layout', timeout: -1, handler: ->
      {hbase} = @config.ryba
      @mkdir
        destination: hbase.rest.pid_dir
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o0755
      @mkdir
        destination: hbase.rest.log_dir
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o0755
      @mkdir
        destination: hbase.rest.conf_dir
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o0755

## HBase Rest Service

    module.exports.push header: 'HBase Rest # Service', handler: ->
      @service
        name: 'hbase-rest'
      @hdp_select
        name: 'hbase-client'
      @render
        source: "#{__dirname}/../resources/hbase-rest"
        local_source: true
        context: @config
        destination: '/etc/init.d/hbase-rest'
        mode: 0o0755
        unlink: true
      @execute
        cmd: "service hbase-rest restart"
        if: -> @status -3

## Opts

Environment passed to the HBase Rest Server before it starts.

    module.exports.push
      header: 'HBase Rest # Opts'
      handler: ->
        {hbase} = @config.ryba
        writes = for k, v of hbase.rest.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
        @render
          source: "#{__dirname}/../resources/hbase-env.sh"
          destination: "#{hbase.rest.conf_dir}/hbase-env.sh"
          local_source: true
          context: @config
          mode: 0o0755
          uid: hbase.user.name
          gid: hbase.group.name
          unlink: true
          write: writes          

## Kerberos

Create the Kerberos keytab for the service principal.

    module.exports.push header: 'HBase Rest # Kerberos', handler: ->
      {hadoop_group, hbase, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: hbase.rest.site['hbase.rest.kerberos.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: hbase.rest.site['hbase.rest.keytab.file']
        uid: hbase.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

## Configure

Note, we left the permission mode as default, Master and RegionServer need to
restrict it but not the rest server.

    module.exports.push header: 'HBase Rest # Configure', handler: ->
      {hbase} = @config.ryba
      @hconfigure
        destination: "#{hbase.rest.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../resources/hbase-site.xml"
        local_default: true
        properties: hbase.rest.site
        merge: false
        uid: hbase.user.name
        gid: hbase.group.name
        backup: true


# User limits

    module.exports.push header: 'HBase Rest # Limits', handler: ->
      {hbase} = @config.ryba
      @system_limits
        user: hbase.user.name
        nofile: hbase.user.limits.nofile
        nproc: hbase.user.limits.nproc

## Logging

    module.exports.push header: 'HBase Rest # Log4J', handler: ->
      {hbase} = @config.ryba
      @write
        destination: "#{hbase.rest.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local_source: true
