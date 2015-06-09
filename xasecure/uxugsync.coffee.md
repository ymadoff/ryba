
# XASecure

    module.exports = []
    module.exports.push 'masson/bootstrap/'
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

    module.exports.push name: 'XASecure Sync # IPTables', handler: (ctx, next) ->
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 5151, protocol: 'tcp', state: 'NEW', comment: "XASecure Admin" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

    module.exports.push name: 'XASecure Sync # Upload', timeout: -1, handler: (ctx, next) ->
      {uxugsync_url} = ctx.config.xasecure
      do_upload = ->
        ctx[if url.parse(uxugsync_url).protocol is 'http:' then 'download' else 'upload']
          source: uxugsync_url
          destination: '/var/tmp'
          binary: true
          not_if_exists: "/var/tmp/#{path.basename uxugsync_url, '.tar'}"
        , (err, uploaded) ->
          return next err, false if err or not uploaded
          modified = true
          do_extract()
      do_extract = ->
        ctx.extract
          source: "/var/tmp/#{path.basename uxugsync_url}"
        , (err) ->
          return next err, true
      do_upload()

    module.exports.push name: 'XASecure Sync # Install', timeout: -1, handler: (ctx, next) ->
      {uxugsync, uxugsync_url} = ctx.config.xasecure
      modified = false
      do_configure = ->
        write = for k, v of uxugsync
          match: RegExp "^#{k} = .*$", 'mg'
          replace: "#{k} = #{v}"
        ctx.write
          destination: "/var/tmp/#{path.basename uxugsync_url, '.tar'}/install.properties"
          write: write
          eof: true
        , (err, written) ->
          return next err, false if err or not written
          do_install()
      do_install = ->
        ctx.execute
          cmd: "cd /var/tmp/#{path.basename uxugsync_url, '.tar'} && ./install.sh"
        , (err, executed) ->
          return next err if err
          next null, true
      do_configure()

## Dependencies

    url = require 'url'
    path = require 'path'
    each = require 'each'
      