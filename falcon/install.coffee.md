
# Falcon Install

This procedure only support 1 Oozie server. If Falcon must interact with
multiple servers, then each Oozie server must be updated. The property
"oozie.service.HadoopAccessorService.hadoop.configurations" shall define
each HDFS cluster.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    # module.exports.push require('masson/core/iptables').configure
    module.exports.push 'ryba/lib/hdp_select'
    # module.exports.push require('./index').configure

## IPTables

| Service   | Port       | Proto     | Parameter                   |
|-----------|------------|-----------|-----------------------------|
| falcon    | 15443      | tcp/http  | prism.falcon.local.endpoint |

Note, this hasnt been verified.

    module.exports.push name: 'Falcon # IPTables', handler: ->
      {falcon} = @config.ryba
      {hostname, port} = url.parse falcon.startup['prism.falcon.local.endpoint']
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'tcp', state: 'NEW', comment: "Falcon Prism Local EndPoint" }
        ]
        if: @config.iptables.action is 'start'

## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep falcon
falcon:x:496:498:Falcon:/var/lib/falcon:/bin/bash
cat /etc/group | grep falcon
falcon:x:498:falcon
```

    module.exports.push name: 'Falcon # Users & Groups', handler: ->
      {falcon} = @config.ryba
      @group falcon.group
      @user falcon.user

## Packages

    module.exports.push name: 'Falcon # Packages', timeout: -1, handler: ->
      @service
        name: 'falcon'
      @hdp_select
        name: 'falcon-server'
      @write
        source: "#{__dirname}/resources/falcon"
        local_source: true
        destination: '/etc/init.d/falcon'
        mode: 0o0755
        unlink: true
      @execute
        cmd: "service falcon restart"
        if: -> @status -3

## Kerberos

    module.exports.push name: 'Falcon # Kerberos', handler: ->
      {realm} = @config.ryba
      {user, group, startup} = @config.ryba.falcon
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: startup['*.falcon.service.authentication.kerberos.principal']#.replace '_HOST', @config.host
        randkey: true
        keytab: startup['*.falcon.service.authentication.kerberos.keytab']
        uid: user.name
        gid: group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

## HFDS Layout

    module.exports.push name: 'Falcon # HFDS Layout', handler: ->
      {user, group} = @config.ryba.falcon
      status = user_owner = group_owner = null
      @execute
        cmd: mkcmd.hdfs @, "hdfs dfs -stat '%g;%u;%n' /apps/falcon"
        code_skipped: 1
      , (err, exists, stdout) ->
        return next err if err
        status = exists
        [user_owner, group_owner, filename] = stdout.trim().split ';' if exists
      @call ->
        @execute
          cmd: mkcmd.hdfs @, 'hdfs dfs -mkdir /apps/falcon'
          unless: -> status
        @execute
          cmd: mkcmd.hdfs @, "hdfs dfs -chown #{user.name} /apps/falcon"
          if: not status or user.name isnt user_owner
        @execute
          cmd: mkcmd.hdfs @, 'hdfs dfs -chgrp #{group.name} /apps/falcon'
          if: not status or group.name isnt group_owner

## Runtime

    # module.exports.push name: 'Falcon # Runtime', handler: ->
    #   # {conf_dir, runtime} = @config.ryba.falcon
    #   # @ini
    #   #   destination: "#{conf_dir}/runtime.properties"
    #   #   content: runtime
    #   #   separator: '='
    #   #   merge: true
    #   #   backup: true
    #   # , next
    #   {conf_dir, runtime} = @config.ryba.falcon
    #   write = for k, v of runtime
    #     match: RegExp "^#{quote k}=.*$", 'mg'
    #     replace: "#{k}=#{v}"
    #   @write
    #     destination: "#{conf_dir}/runtime.properties"
    #     write: write
    #     backup: true
    #     eof: true
    #   , next

## Startup

    module.exports.push name: 'Falcon # Startup', handler: ->
      {conf_dir, startup} = @config.ryba.falcon
      @write
        destination: "#{conf_dir}/startup.properties"
        write: for k, v of startup
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
        backup: true
        eof: true

## Notes

Changes to ownership and permissions of directories managed by Falcon

Directory   Location  Owner   Permissions
Configuration Store   ${config.store.uri}   falcon  750
Oozie coord/bundle XMLs   ${cluster.staging-location}/workflows/{entity}/{entity-name}  falcon  644
Shared libs   {cluster.working}/{lib,libext}  falcon  755
App logs  ${cluster.staging-location}/workflows/{entity}/{entity-name}/logs   falcon  777

## Dependencies

    url = require 'url'
    quote = require 'regexp-quote'
    mkcmd = require '../lib/mkcmd'
