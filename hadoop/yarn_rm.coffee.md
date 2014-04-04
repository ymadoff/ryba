---
title: 
layout: module
---

# YARN ResourceManager

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'phyla/bootstrap'
    module.exports.push 'phyla/hadoop/yarn'

    module.exports.push (ctx) ->
      require('./yarn').configure ctx

    module.exports.push name: 'HDP YARN RM # Kerberos', callback: (ctx, next) ->
      {yarn_user, realm} = ctx.config.hdp
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc 
        principal: "rm/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/rm.service.keytab"
        uid: yarn_user
        gid: 'hadoop'
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , (err, created) ->
        return next err if err
        next null, if created then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP YARN RM # Start', callback: (ctx, next) ->
      lifecycle.rm_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS