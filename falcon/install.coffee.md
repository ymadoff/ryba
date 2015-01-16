
# Falcon Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

# ## IPTables

# | Service   | Port       | Proto     | Parameter                  |
# |-----------|------------|-----------|----------------------------|
# | datanode  | 50010/1004 | tcp/http  | dfs.datanode.address       |
# | datanode  | 50075/1006 | tcp/http  | dfs.datanode.http.address  |
# | datanode  | 50475      | tcp/https | dfs.datanode.https.address |
# | datanode  | 50020      | tcp       | dfs.datanode.ipc.address   |

# The "dfs.datanode.address" default to "50010" in non-secured mode. In non-secured
# mode, it must be set to a value below "1024" and default to "1004".

# IPTables rules are only inserted if the parameter "iptables.action" is set to 
# "start" (default value).

#     module.exports.push name: 'Hadoop HDFS DN # IPTables', handler: (ctx, next) ->
#       {hdfs} = ctx.config.ryba
#       [_, dn_address] = hdfs.site['dfs.datanode.address'].split ':'
#       [_, dn_http_address] = hdfs.site['dfs.datanode.http.address'].split ':'
#       [_, dn_https_address] = hdfs.site['dfs.datanode.https.address'].split ':'
#       [_, dn_ipc_address] = hdfs.site['dfs.datanode.ipc.address'].split ':'
#       ctx.iptables
#         rules: [
#           { chain: 'INPUT', jump: 'ACCEPT', dport: dn_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN Data" }
#           { chain: 'INPUT', jump: 'ACCEPT', dport: dn_http_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN HTTP" }
#           { chain: 'INPUT', jump: 'ACCEPT', dport: dn_https_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN HTTPS" }
#           { chain: 'INPUT', jump: 'ACCEPT', dport: dn_ipc_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN Meta" }
#         ]
#         if: ctx.config.iptables.action is 'start'
#       , next

## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep falcon
falcon:x:496:498:Falcon:/var/lib/falcon:/bin/bash
cat /etc/group | grep falcon
falcon:x:498:falcon
```

    module.exports.push name: 'Falcon # Users & Groups', handler: (ctx, next) ->
      {group, user} = ctx.config.ryba.falcon
      ctx.group group, (err, gmodified) ->
        return next err if err
        ctx.user user, (err, umodified) ->
          next err, gmodified or umodified

## Packages

    module.exports.push name: 'Falcon # Packages', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'falcon'
      , next

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
      , next

    # module.exports.push name: 'Falcon # Runtime', handler: (ctx, next) ->
    #   # {falcon_conf_dir, runtime} = ctx.config.ryba.falcon
    #   # ctx.ini
    #   #   destination: "#{falcon_conf_dir}/runtime.properties"
    #   #   content: runtime
    #   #   separator: '='
    #   #   merge: true
    #   #   backup: true
    #   # , next
    #   {falcon_conf_dir, runtime} = ctx.config.ryba.falcon
    #   write = for k, v of runtime
    #     match: RegExp "^#{quote k}=.*$", 'mg'
    #     replace: "#{k}=#{v}"
    #   ctx.write
    #     destination: "#{falcon_conf_dir}/runtime.properties"
    #     write: write
    #     backup: true
    #     eof: true
    #   , next

    module.exports.push name: 'Falcon # HFDS Layout', handler: (ctx, next) ->
      {user, group} = ctx.config.ryba.falcon
      ctx.execute
        cmd: "hdfs dfs -stat '%g;%u;%n' /apps/falcon"
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


hdfs dfs -mkdir /apps/falcon

    module.exports.push name: 'Falcon # Startup', handler: (ctx, next) ->
      {falcon_conf_dir, startup} = ctx.config.ryba.falcon
      write = for k, v of startup
        match: RegExp "^#{quote k}=.*$", 'mg'
        replace: "#{k}=#{v}"
      ctx.write
        destination: "#{falcon_conf_dir}/startup.properties"
        write: write
        backup: true
        eof: true
      , next

Changes to ownership and permissions of directories managed by Falcon

Directory   Location  Owner   Permissions
Configuration Store   ${config.store.uri}   falcon  750
Oozie coord/bundle XMLs   ${cluster.staging-location}/workflows/{entity}/{entity-name}  falcon  644
Shared libs   {cluster.working}/{lib,libext}  falcon  755
App logs  ${cluster.staging-location}/workflows/{entity}/{entity-name}/logs   falcon  777

## Dependencies

    quote = require 'regexp-quote'
    mkcmd = require '../lib/mkcmd'


