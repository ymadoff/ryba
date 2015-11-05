
# Rexster Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/titan'
    module.exports.push 'ryba/lib/write_jaas'
    # module.exports.push require('./').configure

## Users & Groups

    module.exports.push header: 'Rexster # Users & Groups', handler: ->
      {rexster} = @config.ryba
      @group rexster.group
      @user rexster.user

## IPTables

| Service    | Port  | Proto | Parameter                  |
|------------|-------|-------|----------------------------|
| Hue Web UI | 8182  | http  | config.http.server-port    |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push header: 'Rexster # IPTables', handler: ->
      {rexster} = @config.ryba
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: rexster.config.http['server-port'], protocol: 'tcp', state: 'NEW', comment: "Rexster Web UI" }
        ]
        if: @config.iptables.action is 'start'

## Env

    module.exports.push header: 'Rexster # Env', handler: ->
      {titan, rexster, hadoop_conf_dir} = @config.ryba
      @chown
        destination: rexster.user.home
        uid: rexster.user.name
        gid: rexster.group.name
      write = [
        match: /^(.*)#RYBA CONF hadoop-env, DON'T OVERWRITE/m
        replace: "\tCP=\"$CP:#{hadoop_conf_dir}\" #RYBA CONF hadoop-env, DON'T OVERWRITE"
        append: /^(.*)CP="\$CP:(.*)/m
      ,
        match: /LOG_DIR=.*$/m
        replace: "LOG_DIR=\"#{rexster.log_dir}\" # RYBA CONF \"ryba.rexster.log_dir\", DON'T OVERWRITE"
      ,
        match: /\n(.*)-Dcom.sun.management.jmxremote.port=(.*)\\\n/m
        replace: "\n"
      ,
        match: /^(.*)# RYBA CONF LOG, DON'T OVERWRITE/m
        replace: "JAVA_OPTIONS=\"$JAVA_OPTIONS -Dlog4j.configuration=file:#{path.join rexster.user.home, 'log4j.properties'}\" # RYBA CONF LOG, DON'T OVERWRITE"
        before: /^(.*)com.tinkerpop.rexster.Application.*/m
      ,
        match: /^(.*)-Djava.security.auth.login.config=.*/m
        replace: "JAVA_OPTIONS=\"$JAVA_OPTIONS -Djava.security.auth.login.config=#{path.join rexster.user.home, 'rexster.jaas'}\" # RYBA CONF jaas, DON'T OVERWRITE"
        before: /^(.*)com.tinkerpop.rexster.Application.*/m
      ,
        match: /^(.*)-Djava.library.path.*/m
        replace: "JAVA_OPTIONS=\"$JAVA_OPTIONS -Djava.library.path=/usr/hdp/current/hadoop-client/lib/native\" # RYBA CONF hadoop native libs, DON'T OVERWRITE"
        before: /^(.*)com.tinkerpop.rexster.Application.*/m
      ]
      if titan.config['storage.backend'] is 'hbase'
        # require('../hbase/client').configure @
        write.unshift
          match: /^(.*)# RYBA CONF hbase-env, DON'T OVERWRITE/m
          replace: "\tCP=\"$CP:#{@config.ryba.hbase.conf_dir}\" # RYBA CONF hbase-env, DON'T OVERWRITE"
          append: /^(.*)CP="\$CP:(.*)/m
      @write
        destination: path.join titan.home, 'bin', 'rexster.sh'
        write: write
      @touch
        destination: path.join rexster.log_dir, 'rexstitan.log'
        uid: rexster.user.name
        gid: rexster.group.name

    module.exports.push header: 'Rexster # Tuning', skip: true, handler: ->
      # TODO

## Kerberos JAAS for ZooKeeper

    module.exports.push header: 'Rexster # Kerberos', handler: ->
      {rexster, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: rexster.krb5_user.principal
        randkey: true
        keytab: rexster.krb5_user.keytab
        uid: rexster.user.name
        gid: rexster.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

## Kerberos JAAS for ZooKeeper

Zookeeper use JAAS for authentication. We configure JAAS to make SASL authentication using Kerberos module.

    module.exports.push header: 'Rexster # Kerberos JAAS', handler: ->
      {rexster, realm} = @config.ryba
      @write_jaas
        destination: path.join rexster.user.home, "rexster.jaas"
        content:
          Client:
            principal: rexster.krb5_user.principal
            keyTab: rexster.krb5_user.keytab
          Server:
            principal: rexster.krb5_user.principal
            keyTab: rexster.krb5_user.keytab
        uid: rexster.user.name
        gid: rexster.group.name

    module.exports.push header: 'Rexster # Configure Titan Server', handler: ->
      {titan, rexster, realm} = @config.ryba
      @write
        content: xml 'rexster': rexster.config
        destination: path.join rexster.user.home, 'titan-server.xml'
        uid:rexster.user.name
        gid:rexster.group.name

## Cron-ed Kinit

Rexster doesn't seems to correctly renew its keytab. For that, we use cron daemon
We then ask a first TGT.

    module.exports.push header: 'Rexster # Cron-ed kinit', handler: ->
      {rexster, realm} = @config.ryba
      kinit = "/usr/bin/kinit #{rexster.krb5_user.principal} -k -t #{rexster.krb5_user.keytab}"
      @cron_add
        cmd: kinit
        when: '0 */9 * * *'
        user: rexster.user.name
        exec: true

## HBase Permissions

TODO: Use a namespace

    module.exports.push
      header: 'Rexster # Grant HBase Perms'
      if: -> @config.ryba.titan.config['storage.backend'] is 'hbase'
      handler: ->
        {hbase, titan} = @config.ryba
        table = titan.config['storage.hbase.table']
        @execute
          cmd: mkcmd.hbase @, """
          if hbase shell 2>/dev/null <<< "user_permission '#{table}'" | grep 'rexster'; then exit 3; fi
          hbase shell 2>/dev/null <<< "grant 'rexster', 'RWXCA', '#{table}'"
          """
          code_skipped: 3

## Dependencies

    path = require 'path'
    mkcmd = require '../lib/mkcmd'
    xml = require('jstoxml').toXML
