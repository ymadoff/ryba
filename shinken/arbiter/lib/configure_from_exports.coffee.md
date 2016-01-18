
# Configuration for Servicegroups

    module.exports = ->
      return unless @config.ryba.shinken.exports_dir?
      {servicegroups, hostgroups, hosts, realms} = @config.ryba.shinken.config
      for file in fs.readdirSync @config.ryba.shinken.exports_dir
        continue unless fs.statSync(file).isFile()
        name = path.basename file
        {servers} = require file
        realms[name] ?= {}
        hostgroups[name] ?= {}
        hostgroups[name].members = [hostgroups[name].members] unless Array.isArray hostgroups[name].members
        hostgroups[name].realm ?= name
        for hostname, srv of servers
          hostgroups[name].members.push hostname
          hosts[hostname] ?= {}
          hosts[hostname].ip ?= srv.ip

## Dependencies

    fs = require 'fs'
    path = require 'path'
