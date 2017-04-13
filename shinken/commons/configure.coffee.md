
# Shinken Configure

*   `shinken.user` (object|string)
    The Unix Shinken login name or a user object (see Nikita User documentation).
*   `shinken.group` (object|string)
    The Unix Shinken group name or a group object (see Nikita Group documentation).

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

    module.exports = ->
      shinken = @config.ryba.shinken ?= {}
      throw Error 'Cannot install Shinken: no scheduler provided' unless @contexts('ryba/shinken/scheduler').length
      throw Error 'Cannot install Shinken: no poller provided' unless @contexts('ryba/shinken/poller').length
      throw Error 'Cannot install Shinken: no receiver provided' unless @contexts('ryba/shinken/receiver').length
      throw Error 'Cannot install Shinken: no reactionner provided' unless @contexts('ryba/shinken/reactionner').length
      throw Error 'Cannot install Shinken: no broker provided' unless @contexts('ryba/shinken/broker').length
      throw Error 'Cannot install Shinken: no arbiter provided' unless @contexts('ryba/shinken/arbiter').length
      shinken.build_dir ?= '/var/tmp/ryba/shinken'
      shinken.log_dir ?= '/var/log/shinken'
      shinken.plugin_dir ?= '/usr/lib64/nagios/plugins'
      # User
      shinken.user = name: shinken.user if typeof shinken.user is 'string'
      shinken.user ?= {}
      shinken.user.name ?= 'nagios'
      shinken.user.system ?= true
      shinken.user.comment ?= 'Nagios/Shinken User'
      shinken.user.home ?= '/var/lib/shinken'
      shinken.user.shell ?= '/bin/bash'
      # Groups
      shinken.group = name: shinken.group if typeof shinken.group is 'string'
      shinken.group ?= {}
      shinken.group.name ?= 'nagios'
      shinken.group.system ?= true
      shinken.user.gid = shinken.group.name
      # Config
      shinken.config ?= {}
      shinken.config.use_ssl ?= '0'
      shinken.config.hard_ssl_name_check ?= '0'
      shinken.import_config ?= false
