---
title: 
layout: module
---

# XASecure

    module.exports = []
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/java'

## Configuration

    module.exports.push (ctx) ->
      require('masson/core/iptables').configure ctx
      require('masson/commons/java').configure ctx
      # require('../hadoop/core').configure ctx
      policymgr = ctx.host_with_module 'ryba/xasecure/policymgr'
      xasecure = ctx.config.xasecure ?= {}
      throw new Error "Required property \"xasecure.uxugsync_url\"" unless xasecure.uxugsync_url?
      xasecure.uxugsync ?= {}
      xasecure.uxugsync['POLICY_MGR_URL'] = "http://#{policymgr}:6080"
      # xasecure.uxugsync['SYNC_SOURCE'] = "ldap"
      # xasecure.uxugsync['SYNC_LDAP_URL'] = "ldap://master3.hadoop:389"
      # xasecure.uxugsync['SYNC_LDAP_BIND_DN'] = "cn=Manager,dc=adaltas,dc=com"
      # xasecure.uxugsync['SYNC_LDAP_BIND_PASSWORD'] = "test"
      # xasecure.uxugsync['SYNC_LDAP_USER_SEARCH_BASE'] = "ou=users,dc=adaltas,dc=com"
      # xasecure.uxugsync['SYNC_LDAP_USER_SEARCH_SCOPE'] = "base"
      # xasecure.uxugsync['SYNC_LDAP_USER_OBJECT_CLASS'] = "posixAccount"
      # xasecure.uxugsync['SYNC_LDAP_USER_SEARCH_FILTER'] = ""
      # xasecure.uxugsync['SYNC_LDAP_USER_NAME_ATTRIBUTE'] = "uid"
      # xasecure.uxugsync['SYNC_LDAP_USER_GROUP_NAME_ATTRIBUTE'] = "gidNumber"

## IPTables

| Service    | Port | Proto  | Parameter          |
|------------|------|--------|--------------------|
| XASecure Admin | 5151 | tcp    | - |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'XASecure Sync # IPTables', callback: (ctx, next) ->
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 5151, protocol: 'tcp', state: 'NEW', comment: "XASecure Admin" }
        ]
        if: ctx.config.iptables.action is 'start'
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'XASecure Sync # Install', timeout: -1, callback: (ctx, next) ->
      {uxugsync} = ctx.config.xasecure
      modified = false
      source = ctx.config.xasecure.uxugsync_url
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
          do_configure()
      do_configure = ->
        source = "#{path.dirname source}/#{path.basename source, '.tar'}"
        write = for k, v of uxugsync
          match: RegExp "^#{k} = .*$", 'mg'
          replace: "#{k} = #{v}"
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
          # cwd: "#{source}"
        , (err, executed) ->
          return next err if err
          next null, ctx.OK
      do_upload()

## Module Dependencies

    url = require 'url'
    path = require 'path'
    each = require 'each'
      