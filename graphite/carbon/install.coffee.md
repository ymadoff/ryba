
# Graphite Carbon Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/httpd'

## Configure

*   `carbon_user` (object|string)
    The Unix RRDtool login name or a user object (see Mecano User documentation).
*   `carbon_group` (object|string)
    The Unix Hue group name or a group object (see Mecano Group documentation).

Example:

```json
{
  "graphite": {
    "carbon_user": {
      "name": "carbon", "system": true, "gid": "carbon", "shell": false
      "comment": "Graphite Carbon User", "home": "/usr/lib/carbon"
    }
    "carbon_group": {
      "name": "Hue", "system": true
    }
  }
}
```
    console.log "hello"
    module.exports.push require('./index').configure


## IPTables

#| Service        | Port | Proto | Info                                 |
#|----------------|------|-------|--------------------------------------|
#| carbon-cache   | 2003 | tcp   | Graphite Carbon Daemon               |
#
#IPTables rules are only inserted if the parameter "iptables.action" is set to
#"start" (default value).
#
#    module.exports.push name: 'Graphite Carbon # IPTables', handler: (ctx, next) ->
#      ctx.iptables
#        rules: [
#          { chain: 'INPUT', jump: 'ACCEPT', dport: 2003, protocol: 'tcp', state: 'NEW', comment: "Graphite Carbon Daemon" }
#        ]
#        if: ctx.config.iptables.action is 'start'
#      , next


## Start

    #module.exports.push 'ryba/graphite/collector/start'

## Check

    #module.exports.push 'ryba/graphite/collector/check'

## Dependencies

    request = require 'request'
    glob = require 'glob'
