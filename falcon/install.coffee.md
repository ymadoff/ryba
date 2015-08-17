
# Falcon Install

This procedure only support 1 Oozie server. If Falcon must interact with
multiple servers, then each Oozie server must be updated. The property
"oozie.service.HadoopAccessorService.hadoop.configurations" shall define
each HDFS cluster.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push require('masson/core/iptables').configure
    module.exports.push require '../lib/hdp_select'
    module.exports.push require('./index').configure

## IPTables

| Service   | Port       | Proto     | Parameter                   |
|-----------|------------|-----------|-----------------------------|
| falcon    | 15443      | tcp/http  | prism.falcon.local.endpoint |

Note, this hasnt been verified.

    module.exports.push name: 'Falcon # IPTables', handler: (ctx, next) ->
      {falcon} = ctx.config.ryba
      {hostname, port} = url.parse falcon.startup['prism.falcon.local.endpoint']
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'tcp', state: 'NEW', comment: "Falcon Prism Local EndPoint" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep falcon
falcon:x:496:498:Falcon:/var/lib/falcon:/bin/bash
cat /etc/group | grep falcon
falcon:x:498:falcon
```

    module.exports.push name: 'Falcon # Users & Groups', handler: (ctx, next) ->
      {falcon} = ctx.config.ryba
      ctx.group falcon.group
      .user falcon.user
      .then next

## Packages

    module.exports.push name: 'Falcon # Packages', timeout: -1, handler: (ctx, next) ->
      ctx
      .service
        name: 'falcon'
      .hdp_select
        name: 'falcon-server'
      .write
        source: "#{__dirname}/resources/falcon"
        local_source: true
        destination: '/etc/init.d/falcon'
        mode: 0o0755
        unlink: true
      .execute
        cmd: "service falcon restart"
        if: -> @status(-3)
      .then next

## Kerberos

    module.exports.push name: 'Falcon # Kerberos', handler: (ctx, next) ->
      {realm} = ctx.config.ryba
      {user, group, startup} = ctx.config.ryba.falcon
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: startup['*.falcon.service.authentication.kerberos.principal']#.replace '_HOST', ctx.config.host
        randkey: true
        keytab: startup['*.falcon.service.authentication.kerberos.keytab']
        uid: user.name
        gid: group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      .then next

## HFDS Layout

    module.exports.push name: 'Falcon # HFDS Layout', handler: (ctx, next) ->
      {user, group} = ctx.config.ryba.falcon
      ctx.call (_, next) ->
        ctx.execute
          cmd: mkcmd.hdfs ctx, "hdfs dfs -stat '%g;%u;%n' /apps/falcon"
          code_skipped: 1
        , (err, exists, stdout) ->
          return next err if err
          [user_owner, group_owner, filename] = stdout.trim().split ';' if exists
          ctx.execute [
            cmd: mkcmd.hdfs ctx, 'hdfs dfs -mkdir /apps/falcon'
            not_if: exists
          ,
            cmd: mkcmd.hdfs ctx, "hdfs dfs -chown #{user.name} /apps/falcon"
            if: not exists or user.name isnt user_owner
          ,
            cmd: mkcmd.hdfs ctx, 'hdfs dfs -chgrp #{group.name} /apps/falcon'
            if: not exists or group.name isnt group_owner
          ], next
      .then next

## Runtime

    # module.exports.push name: 'Falcon # Runtime', handler: (ctx, next) ->
    #   # {conf_dir, runtime} = ctx.config.ryba.falcon
    #   # ctx.ini
    #   #   destination: "#{conf_dir}/runtime.properties"
    #   #   content: runtime
    #   #   separator: '='
    #   #   merge: true
    #   #   backup: true
    #   # , next
    #   {conf_dir, runtime} = ctx.config.ryba.falcon
    #   write = for k, v of runtime
    #     match: RegExp "^#{quote k}=.*$", 'mg'
    #     replace: "#{k}=#{v}"
    #   ctx.write
    #     destination: "#{conf_dir}/runtime.properties"
    #     write: write
    #     backup: true
    #     eof: true
    #   , next

## Startup

    module.exports.push name: 'Falcon # Startup', handler: (ctx, next) ->
      {conf_dir, startup} = ctx.config.ryba.falcon
      write = for k, v of startup
        match: RegExp "^#{quote k}=.*$", 'mg'
        replace: "#{k}=#{v}"
      ctx.write
        destination: "#{conf_dir}/startup.properties"
        write: write
        backup: true
        eof: true
      .then next

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
