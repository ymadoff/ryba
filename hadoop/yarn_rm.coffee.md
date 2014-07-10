---
title: 
layout: module
---

# YARN ResourceManager

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hadoop/yarn'

    module.exports.push (ctx) ->
      require('./yarn').configure ctx

## IPTables

| Service    | Port | Proto  | Parameter                  |
|------------|------|--------|----------------------------|
| resourcemanager | 8025  | tcp    | yarn.resourcemanager.resource-tracker.address | x
| resourcemanager | 8050  | tcp    | yarn.resourcemanager.address                  | x
| scheduler       | 8030  | tcp    | yarn.resourcemanager.scheduler.address        | x
| resourcemanager | 8088  | http   | yarn.resourcemanager.webapp.address           | x
| resourcemanager | 8090  | https  | yarn.resourcemanager.webapp.https.address     | 
| resourcemanager | 8141  | tcp    | yarn.resourcemanager.admin.address            | x

| Service    | Port | Proto  | Parameter                  |
|------------|------|--------|----------------------------|
| timeline | 10200 | tcp    | yarn.timeline-service.address                 | 
| timeline | 8188  | tcp    | yarn.timeline-service.webapp.address          | x
| timeline | 8190  | tcp    | yarn.timeline-service.webapp.https.address    | x

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'HDP YARN RM # IPTables', callback: (ctx, next) ->
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8025, protocol: 'tcp', state: 'NEW', comment: "YARN RM Application Submissions" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8050, protocol: 'tcp', state: 'NEW', comment: "YARN RM Application Submissions" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8030, protocol: 'tcp', state: 'NEW', comment: "YARN Scheduler" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8088, protocol: 'tcp', state: 'NEW', comment: "YARN RM Web UI" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8090, protocol: 'tcp', state: 'NEW', comment: "YARN RM Web Secured UI" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8141, protocol: 'tcp', state: 'NEW', comment: "YARN RM Scheduler" }
        ]
        if: ctx.config.iptables.action is 'start'
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP YARN RM # Kerberos', callback: (ctx, next) ->
      {yarn_user, hadoop_group, realm} = ctx.config.hdp
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc 
        principal: "rm/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/rm.service.keytab"
        uid: yarn_user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , (err, created) ->
        return next err if err
        next null, if created then ctx.OK else ctx.PASS

## Wait JHS

Yarn use the the MapReduce Job History Server (JHS) to send logs. The address of
the server is defined by the propery "yarn.log.server.url" in "yarn-site.xml".
The default port is "19888".

    # url = require 'url'
    # module.exports.push name: 'HDP YARN RM # Wait JHS', timeout: -1, callback: (ctx, next) ->
    #   {hostname, port} = url.parse ctx.config.hdp.yarn['yarn.log.server.url']
    #   ctx.waitIsOpen hostname, port, (err) ->
    #     return next err if err

## Start RM

Execute the "ryba/hadoop/yarn_rm_start" module to start the Resource Manager.

    module.exports.push 'ryba/hadoop/yarn_rm_start'




