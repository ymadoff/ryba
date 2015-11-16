
# XASecure

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/java'

## Configuration

    module.exports.push (ctx) ->
      require('masson/core/iptables').configure ctx
      require('masson/commons/java').configure ctx
      # require('../hadoop/core').configure ctx
      policymgr = @host_with_module 'ryba/xasecure/policymgr'
      xasecure = @config.xasecure ?= {}
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

    module.exports.push header: 'XASecure Sync # IPTables', handler: ->
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 5151, protocol: 'tcp', state: 'NEW', comment: "XASecure Admin" }
        ]
        if: @config.iptables.action is 'start'

    module.exports.push header: 'XASecure Sync # Upload', timeout: -1, handler: ->
      {uxugsync_url} = @config.xasecure
      @download
        source: uxugsync_url
        destination: '/var/tmp'
        binary: true
        unless_exists: "/var/tmp/#{path.basename uxugsync_url, '.tar'}"
      @extract
        source: "/var/tmp/#{path.basename uxugsync_url}"
        if: -> @status -1

    module.exports.push header: 'XASecure Sync # Install', timeout: -1, handler: ->
      {uxugsync, uxugsync_url} = @config.xasecure
      @write
        destination: "/var/tmp/#{path.basename uxugsync_url, '.tar'}/install.properties"
        write: for k, v of uxugsync
          match: RegExp "^#{k} = .*$", 'mg'
          replace: "#{k} = #{v}"
        eof: true
      @execute
        cmd: "cd /var/tmp/#{path.basename uxugsync_url, '.tar'} && ./install.sh"

## Dependencies

    url = require 'url'
    path = require 'path'
    each = require 'each'
      
