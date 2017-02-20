
# Falcon Server Install

This procedure only support 1 Oozie server. If Falcon must interact with
multiple servers, then each Oozie server must be updated. The property
"oozie.service.HadoopAccessorService.hadoop.configurations" shall define
each HDFS cluster.

    module.exports = header: 'Falcon Server Install', handler: ->
      {falcon, realm} = @config.ryba
      {user, group, startup, runtime, conf_dir} = @config.ryba.falcon
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      {hostname, port} = url.parse falcon.runtime['prism.falcon.local.endpoint']

## Register

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'

## IPTables

| Service   | Port       | Proto     | Parameter                   |
|-----------|------------|-----------|-----------------------------|
| Falcon Serveur    | 15443      | tcp/http  | prism.falcon.local.endpoint |
| falcon Prism    | 16443      | tcp/http  | prism.falcon.local.endpoint |

Note, this hasnt been verified.

      @tools.iptables
        header: 'IPTables'
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

      @system.group falcon.group
      @system.user falcon.user

## Packages

      @call header: 'Packages', timeout: -1, handler: ->
        @service
          name: 'falcon'
        @hdp_select
          name: 'falcon-server'
        @file
          header: 'Init Script'
          source: "#{__dirname}/../resources/falcon"
          local_source: true
          target: '/etc/init.d/falcon'
          mode: 0o0755
          unlink: true
        @execute
          cmd: "service falcon restart"
          if: -> @status -3

      @call header: 'Layout', handler: ->
        @system.mkdir
          target: falcon.log_dir
          uid: falcon.user
          gid: falcon.group
          parent: true
        @system.mkdir
          target: falcon.pid_dir
          uid: falcon.user.name
          gid: falcon.group.name
          parent: true

## Environnement

Enrich the file "mapred-env.sh" present inside the Hadoop configuration
directory with the location of the directory storing the process pid.

Templated properties are "ryba.mapred.heapsize" and "ryba.mapred.pid_dir".

      @file.render
        header: 'Falcon Env'
        target: "#{falcon.conf_dir}/falcon-env.sh"
        source: "#{__dirname}/../resources/falcon-env.sh.j2"
        context: @config
        local_source: true
        backup: true

## Kerberos

      @krb5_addprinc krb5,
        header: 'Kerberos'
        principal: startup['*.falcon.service.authentication.kerberos.principal']#.replace '_HOST', @config.host
        randkey: true
        keytab: startup['*.falcon.service.authentication.kerberos.keytab']
        uid: user.name
        gid: group.name

## HDFS Layout

      @call header: 'HDFS Layout', handler: ->
        # status = user_owner = group_owner = null
        # @execute
        #   cmd: mkcmd.hdfs @, "hdfs dfs -stat '%g;%u;%n' /apps/falcon"
        #   code_skipped: 1
        # , (err, exists, stdout) ->
        #   return next err if err
        #   status = exists
        #   [user_owner, group_owner, filename] = stdout.trim().split ';' if exists
        # @call ->
        #   @execute
        #     cmd: mkcmd.hdfs @, 'hdfs dfs -mkdir /apps/falcon'
        #     unless: -> status
        #   @execute
        #     cmd: mkcmd.hdfs @, "hdfs dfs -chown #{user.name} /apps/falcon"
        #     if: not status or user.name isnt user_owner
        #   @execute
        #     cmd: mkcmd.hdfs @, "hdfs dfs -chgrp #{group.name} /apps/falcon"
        #     if: not status or group.name isnt group_owner
        @hdfs_mkdir
          target: '/apps/falcon'
          user: "#{user.name}"
          group: "#{group.name}"
          mode: 0o1777
          krb5_user: @config.ryba.hdfs.krb5_user
        @hdfs_mkdir
          target: '/apps/data-mirroring'
          user: "#{user.name}"
          group: "#{group.name}"
          mode: 0o0770
          krb5_user: @config.ryba.hdfs.krb5_user
        @execute
          shy: true
          cmd: """
          hdfs dfs -copyFromLocal -f /usr/hdp/current/falcon-server/data-mirroring /apps
          hdfs dfs -chown -R #{user.name}:#{group.name} /apps/data-mirroring
          """

## Runtime

    # module.exports.push header: 'Falcon Runtime', handler: ->
    #   # {conf_dir, runtime} = @config.ryba.falcon
    #   # @file.ini
    #   #   target: "#{conf_dir}/runtime.properties"
    #   #   content: runtime
    #   #   separator: '='
    #   #   merge: true
    #   #   backup: true
    #   # , next
    #   {conf_dir, runtime} = @config.ryba.falcon
    #   write = for k, v of runtime
    #     match: RegExp "^#{quote k}=.*$", 'mg'
    #     replace: "#{k}=#{v}"
    #   @file
    #     target: "#{conf_dir}/runtime.properties"
    #     write: write
    #     backup: true
    #     eof: true
    #   , next

## Configuration

      @file
        header: 'Configuration startup'
        target: "#{conf_dir}/startup.properties"
        write: for k, v of startup
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
        backup: true
        eof: true
      @file
        header: 'Configuration runtime'
        target: "#{conf_dir}/runtime.properties"
        write: for k, v of runtime
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
    mkcmd = require '../../lib/mkcmd'
