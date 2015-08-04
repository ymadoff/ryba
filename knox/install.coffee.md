
# Knox Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/core/yum'
    module.exports.push require '../lib/hconfigure'
    module.exports.push require '../lib/write_jaas'
    module.exports.push require('./').configure

## Users & Groups

    module.exports.push name: 'Knox # Users & Groups', handler: (ctx, next) ->
      {knox} = ctx.config.ryba
      ctx
      .group knox.group
      .user knox.user
      .then next

## IPTables

| Service        | Port  | Proto | Parameter       |
|----------------|-------|-------|-----------------|
| Gateway        | 8443  | http  | gateway.port    |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'Knox # IPTables', handler: (ctx, next) ->
      {knox} = ctx.config.ryba
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: knox.site['gateway.port'], protocol: 'tcp', state: 'NEW', comment: "Knox Gateway" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Service

    module.exports.push name: 'Knox # Service', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'knox'
      .then next

## Master Secret

    module.exports.push name: 'Knox # Master Secret', handler: (ctx, next) ->
      {knox} = ctx.config.ryba
      ctx.fs.exists '/usr/hdp/current/knox-server/data/security/master', (err, exists) ->
        return next err, false if err or exists
        ctx.ssh.shell (err, stream) ->
          return next err if err
          emitted = done = false
          stream.write "su -l #{knox.user.name} -c '/usr/hdp/current/knox-server/bin/knoxcli.sh create-master'\n"
          stream.on 'data', (data, stderr) ->
            ctx.log[if stderr then 'err' else 'out'].write data
            data = data.toString()
            if emitted
              # Wait the end
            else if done
              emitted = true
              stream.end 'exit\n'
            else if /Enter master secret:/.test data
              stream.write "#{knox.master_secret}\n"
            else if /Enter master secret again:/.test data
              stream.write "#{knox.master_secret}\n"
              done = true
          stream.on 'exit', ->
            return next Error 'Exit before the end' unless done
            next null, done
          stream.pipe ctx.log.out
          stream.stderr.pipe ctx.log.err
      # su -l knox -c '$gateway_home/bin/knoxcli.sh create-master'
      # MySecret

## Configure

    module.exports.push name: 'Knox # Configure', handler: (ctx, next) ->
      {knox} = ctx.config.ryba
      ctx
      .hconfigure
        destination: "#{knox.conf_dir}/gateway-site.xml"
        properties: knox.site
        merge: true
      .then next

## Kerberos

    module.exports.push name: 'Knox # Kerberos', handler: (ctx, next) ->
      {knox, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: knox.krb5_user.principal
        randkey: true
        keytab: knox.krb5_user.keytab
        uid: knox.user.name
        gid: knox.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      .write_jaas
        destination: knox.site['java.security.auth.login.config']
        content: 'com.sun.security.jgss.initiate':
          principal: knox.krb5_user.principal
          keyTab: knox.krb5_user.keytab
          renewTGT: true
          doNotPrompt: true
          isInitiator: true
          useTicketCache: true
          client: true
        no_entry_check: true
        uid: knox.user.name
        gid: knox.group.name
        mode: 0o700
      .then next

## Topologies

    module.exports.push name: 'Knox # Topologies', handler: (ctx, next) ->
      {knox} = ctx.config.ryba
      write = []
      for nameservice, topology of knox.topologies
        doc = builder.create 'configuration', version: '1.0', encoding: 'UTF-8'
        gateway = doc.ele 'gateway'
        for name, p of topology.providers
          provider = gateway.ele 'provider'
          provider.ele 'name', name
          provider.ele 'role', p.role
          provider.ele 'enabled', 'true'
          for name, value of p.config
            param = provider.ele 'param'
            param.ele 'name', name
            param.ele 'value', value
        for role, url of topology.services
          service = doc.ele 'service'
          service.ele 'role', role.toUpperCase()
          if Array.isArray url then for u in url
            service.ele 'url', u
          else service.ele 'url', url
        write.push
          destination: "#{knox.conf_dir}/topologies/#{nameservice}.xml"
          content: doc.end pretty: true
      ctx
      .remove
         destination: "#{knox.conf_dir}/topologies/sandbox.xml"
         not_if: 'sandbox' in Object.keys knox.topologies
      .write write
      .then next

## Dependencies

    builder = require 'xmlbuilder'
