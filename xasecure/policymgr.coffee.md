---
title: 
layout: module
---

# XASecure Policy Manager

    module.exports = []
    module.exports.push 'masson/commons/mysql_client'
    module.exports.push 'masson/commons/java'
    # module.exports.push 'ryba/hadoop/hdfs_client'

## Configuration

    module.exports.push module.exports.configure = (ctx) ->
      require('masson/commons/java').configure ctx
      require('../hadoop/core').configure ctx
      {db_admin} = ctx.config.hdp
      {java_home} = ctx.config.java
      xasecure = ctx.config.xasecure ?= {}
      throw new Error "Required property \"xasecure.policymgr_url\"" unless xasecure.policymgr_url?
      throw new Error "Required property \"xasecure.uxugsync_url\"" unless xasecure.uxugsync_url?
      throw new Error "Required property \"xasecure.hbase_url\"" unless xasecure.hbase_url?
      throw new Error "Required property \"xasecure.hive_url\"" unless xasecure.hive_url?
      # User
      xasecure.user = name: ctx.config.xasecure.user if typeof ctx.config.xasecure.user is 'string'
      xasecure.user ?= {}
      xasecure.user.name ?= 'xasecure'
      xasecure.user.system ?= true
      xasecure.user.gid ?= 'xasecure'
      xasecure.user.comment ?= 'XASecure User'
      xasecure.user.home ?= '/var/lib/xasecure'
      # Group
      xasecure.group = name: ctx.config.xasecure.group if typeof ctx.config.xasecure.group is 'string'
      xasecure.group ?= {}
      xasecure.group.name ?= 'xasecure'
      xasecure.group.system ?= true
      # DB Config
      xasecure.policymgr ?= {}
      xasecure.policymgr['MYSQL_BIN'] ?= "'#{db_admin.path}'"
      xasecure.policymgr['MYSQL_CONNECTOR_JAR'] ?= "/usr/share/java/mysql-connector-java.jar"
      xasecure.policymgr['db_root_password'] ?= "#{db_admin.password}"
      xasecure.policymgr['db_host'] ?= "#{db_admin.host}"
      xasecure.policymgr['db_user'] ?= "xasecure"
      xasecure.policymgr['db_name'] ?= "xasecure"
      xasecure.policymgr['db_password'] ?= "XaSecure123"
      xasecure.policymgr['audit_db_name'] ?= "xasecure"
      xasecure.policymgr['audit_db_user'] ?= "xalogger"
      xasecure.policymgr['audit_db_password'] ?= "XaLogger123"
      xasecure.policymgr['policymgr_external_url'] ?= "http://#{ctx.config.host}:6080"
      xasecure.policymgr['policymgr_http_enabled'] ?= "true"
      xasecure.policymgr['JAVA_HOME'] ?= "#{java_home}"
      xasecure.policymgr['unix_user'] ?= "xasecure"
      xasecure.policymgr['unix_group'] ?= "xasecure"
      # xasecure.policymgr['authentication_method'] ?= "LDAP"
      # xasecure.policymgr['remoteLoginEnabled'] ?= "true"
      # xasecure.policymgr['authServiceHostName'] ?= "master3.hadoop"
      # xasecure.policymgr['authServicePort'] ?= "389"
      # xasecure.policymgr['xa_ldap_url'] ?= "\"ldap://master3.hadoop:389\""
      # xasecure.policymgr['xa_ldap_userDNpattern'] ?= "\"uid={0},ou=users,dc=adaltas,dc=com\""
      # xasecure.policymgr['xa_ldap_groupSearchBase'] ?= "\"ou=groups,dc=adaltas,dc=com\""
      # xasecure.policymgr['xa_ldap_groupSearchFilter'] ?= "\"(memberUid={0})\""
      # xasecure.policymgr['xa_ldap_groupRoleAttribute'] ?= "cn"

## Users & Groups

By default, the "xasecure" package create the following entries:

```bash
cat /etc/passwd | grep xasecure
xasecure:x:493:493::/home/xasecure:/bin/bash
cat /etc/group | grep xasecure
xasecure:x:493:
```

    module.exports.push name: 'XASecure PolicyMgr # Users & Groups', callback: (ctx, next) ->
      {group, user} = ctx.config.xasecure
      ctx.group group, (err, gmodified) ->
        return next err if err
        ctx.user user, (err, umodified) ->
          next err, if gmodified or umodified then ctx.OK else ctx.PASS

## IPTables

| Service    | Port | Proto  | Parameter          |
|------------|------|--------|--------------------|
| XASecure Admin | 6080 | tcp    | policymgr\_external\_url |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'XASecure PolicyMgr # IPTables', callback: (ctx, next) ->
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 6080, protocol: 'tcp', state: 'NEW', comment: "XASecure Admin" }
        ]
        if: ctx.config.iptables.action is 'start'
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'XASecure PolicyMgr # Install', timeout: -1, callback: (ctx, next) ->
      {db_admin} = ctx.config.hdp
      {policymgr} = ctx.config.xasecure
      modified = false
      source = ctx.config.xasecure.policymgr_url
      do_upload = ->
        u = url.parse source
        ctx[if u.protocol is 'http:' then 'download' else 'upload']
          source: source
          destination: '/tmp'
          binary: true
        , (err, uploaded) ->
          return next err if err
          do_extract()
      do_extract = ->
        source = "/tmp/#{path.basename source}"
        ctx.extract
          source: source
        , (err) ->
          return next err if err
          do_fix_mysql_root()
      do_fix_mysql_root = ->
        ctx.write
          destination: "/tmp/xasecure-policymgr-3.5.000-release/install.sh"
          match: "-u root"
          replace: "-u #{db_admin.username}"
        , (err) ->
          return next err if err
          do_configure()
      do_configure = ->
        source = "#{path.dirname source}/#{path.basename source, '.tar'}"
        write = for k, v of policymgr
          match: RegExp "^#{k}=.*$", 'mg'
          replace: "#{k}=#{v}"
        ctx.write
          destination: "#{source}/install.properties"
          write: write
          eof: true
        , (err, written) ->
          return next err if err
          do_install()
      do_install = ->
        ctx.execute
          cmd: "cd #{source} && ./install.sh"
        , (err, executed) ->
          return next err if err
          next()
      do_upload()

## Module Dependencies

    url = require 'url'
    path = require 'path'
    each = require 'each'
