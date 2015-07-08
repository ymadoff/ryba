
# Shinken

Shinken is the distributed, fault-tolerant successor of Nagios.
Nagios plugins and configuration are fully compatible with Shinken.

    module.exports = []

## Configure

*   `shinken.user` (object|string)
    The Unix Shinken login name or a user object (see Mecano User documentation).
*   `shinken.group` (object|string)
    The Unix Shinken group name or a group object (see Mecano Group documentation).

Example

```json
    "shinken":{
      "user": {
        "name": "shinken", "system": true, "gid": "shinken",
        "comment": "Shinken User"
      },
      "group": {
        "name": "shinken", "system": true
      }
    }
```

    module.exports.push module.exports.configure = (ctx) ->
      ctx.config.ryba.shinken ?= {}
      {shinken, realm} = ctx.config.ryba
      shinken.log_dir = '/var/log/shinken'
      # User
      shinken.user = name: shinken.user if typeof shinken.user is 'string'
      shinken.user ?= {}
      shinken.user.name ?= 'nagios'
      shinken.user.system ?= true
      shinken.user.comment ?= 'Shinken User'
      shinken.user.home ?= '/var/lib/shinken'
      shinken.user.shell ?= '/bin/sh'
      shinken.plugin_dir ?= '/usr/lib64/nagios/plugins/'
      # Kerberos
      # shinken.krb5_user ?= {}
      # shinken.krb5_user.principal ?= "#{shinken.user.name}/#{ctx.config.host}@#{realm}"
      # shinken.krb5_user.keytab ?= "/etc/security/keytabs/shinken.service.keytab"
      # Config
      shinken.config ?= {}
      shinken.config.use_ssl ?= false
      shinken.config.hard_ssl_name_check ?= false
      # Groups
      shinken.group = name: shinken.group if typeof shinken.group is 'string'
      shinken.group ?= {}
      shinken.group.name ?= 'nagios'
      shinken.group.system ?= true
      shinken.user.gid = shinken.group.name


## Users & Groups

    module.exports.push name: 'Shinken # Users & Groups', handler: (ctx, next) ->
      {shinken} = ctx.config.ryba
      ctx
      .group shinken.group
      .user shinken.user
      .then next
