---
title: 
layout: module
---

# YARN ResourceManager

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'riba/hadoop/yarn'

    module.exports.push (ctx) ->
      require('./yarn').configure ctx

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

Execute the "riba/hadoop/yarn_rm_start" module to start the Resource Manager.

    module.exports.push 'riba/hadoop/yarn_rm_start'

    # module.exports.push name: 'HDP YARN RM # Start', callback: (ctx, next) ->
    #   lifecycle.rm_start ctx, (err, started) ->
    #     next err, if started then ctx.OK else ctx.PASS



