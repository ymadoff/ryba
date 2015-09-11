
# HBase Master Install

TODO: [HBase backup node](http://willddy.github.io/2013/07/02/HBase-Add-Backup-Master-Node.html)

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push 'ryba/hbase'
    # module.exports.push require('./index').configure
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdp_select'
    module.exports.push require '../../lib/write_jaas'

## IPTables

| Service             | Port  | Proto | Info                   |
|---------------------|-------|-------|------------------------|
| HBase Master        | 60000 | http  | hbase.master.port      |
| HMaster Info Web UI | 60010 | http  | hbase.master.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'HBase Master # IPTables', handler: ->
      {hbase} = @config.ryba
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.master.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.master.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Info Web UI" }
        ]
        if: @config.iptables.action is 'start'

## Service

Install the "hbase-master" service, symlink the rc.d startup script inside
"/etc/init.d" and activate it on startup.

    module.exports.push name: 'HBase Master # Service', timeout: -1, handler: ->
      @service
        name: 'hbase-master'
      @hdp_select
        name: 'hbase-client'
      @hdp_select
        name: 'hbase-master'
      @write
        source: "#{__dirname}/../resources/hbase-master"
        local_source: true
        destination: '/etc/init.d/hbase-master'
        mode: 0o0755
        unlink: true
      @execute
        cmd: "service hbase-master restart"
        if: -> @status -4

## Configure

*   [New Security Features in Apache HBase 0.98: An Operator's Guide][secop].

[secop]: http://fr.slideshare.net/HBaseCon/features-session-2

    module.exports.push name: 'HBase Master # Configure', handler: ->
      {hbase} = @config.ryba
      mode = if @has_module 'ryba/hbase/client' then 0o0644 else 0o0600
      @hconfigure
        destination: "#{hbase.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../../resources/hbase/hbase-site.xml"
        local_default: true
        properties: hbase.site
        merge: true
        uid: hbase.user.name
        gid: hbase.group.name
        mode: mode # See slide 33 from [Operator's Guide][secop]
        backup: true

# Opts

Environment passed to the Master before it starts.

    module.exports.push name: 'HBase Master # Opts', handler: ->
      {hbase} = @config.ryba
      @write
        destination: "#{hbase.conf_dir}/hbase-env.sh"
        match: /^export HBASE_MASTER_OPTS="(.*)" # RYBA(.*)$/m
        replace: "export HBASE_MASTER_OPTS=\"#{hbase.master_opts} ${HBASE_MASTER_OPTS}\" # RYBA CONF \"ryba.hbase.master_opts\", DONT OVERWRITE"
        before: /^export HBASE_MASTER_OPTS=".*"$/m
        backup: true

      #  match: /^export HBASE_ROOT_LOGGER=.*$/mg
      #  replace: "export HBASE_ROOT_LOGGER=#{hbase.master.log4j.root_logger}"
      #  append: true
      #  match: /^export HBASE_SECURITY_LOGGER=.*$/mg
      #  replace: "export HBASE_SECURITY_LOGGER=#{hbase.master.log4j.security_logger}"
      #  append: true


    module.exports.push 'ryba/hadoop/hdfs_nn/wait'

    module.exports.push name: 'HBase Master # HDFS layout', timeout: -1, handler: ->
      {hbase} = @config.ryba
      @wait_execute
        cmd: mkcmd.hdfs @, "hdfs dfs -test -d /apps"
      @call ->
        dirs = hbase.site['hbase.bulkload.staging.dir'].split '/'
        throw err "Invalid property \"hbase.bulkload.staging.dir\"" unless dirs.length > 2 and path.join('/', dirs[0], '/', dirs[1]) is '/apps'
        for dir, index in dirs.slice 2
          dir = dirs.slice(0, 3 + index).join '/'
          cmd = """
          if hdfs dfs -ls #{dir} &>/dev/null; then exit 2; fi
          hdfs dfs -mkdir #{dir}
          hdfs dfs -chown #{hbase.user.name} #{dir}
          """
          cmd += "\nhdfs dfs -chmod 711 #{dir}"  if 3 + index is dirs.length
          @execute
            cmd: mkcmd.hdfs @, cmd
            code_skipped: 2

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master,
RegionServer, and HBase client host machines.

Environment file is enriched by "ryba/hbase" # HBase # Env".

    module.exports.push name: 'HBase Master # Zookeeper JAAS', timeout: -1, handler: ->
      {hbase} = @config.ryba
      @write_jaas
        destination: "#{hbase.conf_dir}/hbase-master.jaas"
        content: Client:
          principal: hbase.site['hbase.master.kerberos.principal'].replace '_HOST', @config.host
          keyTab: hbase.site['hbase.master.keytab.file']
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o700

## Kerberos

https://blogs.apache.org/hbase/entry/hbase_cell_security
https://hbase.apache.org/book/security.html

    module.exports.push name: 'HBase Master # Kerberos', handler: ->
      {hadoop_group, hbase, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: hbase.site['hbase.master.kerberos.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: hbase.site['hbase.master.keytab.file']
        uid: hbase.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

    module.exports.push name: 'HBase Master # Kerberos Admin', handler: ->
      {hbase, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: hbase.admin.principal
        password: hbase.admin.password
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server


    module.exports.push name: 'HBase Master # Log4J', handler: ->
      {hbase} = @config.ryba
      @write
        destination: "#{hbase.conf_dir}/log4j.properties"
        source: "#{__dirname}/../../resources/hbase/log4j.properties"
        local_source: true


## Metrics

Enable stats collection in Ganglia and Graphite

    module.exports.push name: 'HBase Master # Metrics', handler: ->
      {hbase} = @config.ryba
      content = ""
      for k, v of hbase.metrics
        content += "#{k}=#{v}\n" if v?
      @write
        destination: "#{hbase.conf_dir}/hadoop-metrics2-hbase.properties"
        content: content
        backup: true

## SPNEGO

Ensure we have read access to the spnego keytab soring the server HTTP
principal.

    module.exports.push name: 'HBase RegionServer # SPNEGO', handler: ->
      {hbase} = @config.ryba
      @execute
        cmd: "su -l #{hbase.user.name} -c 'test -r /etc/security/keytabs/spnego.service.keytab'"

# Module dependencies

    path = require 'path'
    mkcmd = require '../../lib/mkcmd'
    quote = require 'regexp-quote'
