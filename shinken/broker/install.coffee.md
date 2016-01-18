
# Shinken Broker Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/mongodb'

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
|  shinken-broker   | 7772  |  tcp  |   config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push header: 'Shinken Broker # IPTables', handler: ->
      {broker} = @config.ryba.shinken
      rules = [{ chain: 'INPUT', jump: 'ACCEPT', dport: broker.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Broker" }]
      for name, mod of broker.modules
        if mod.config?.port?
          rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: mod.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Broker #{name}" }
      @iptables
        rules: rules
        if: @config.iptables.action is 'start'

## Packages

    module.exports.push header: 'Shinken Broker # Packages', handler: ->
      @service name: 'shinken-broker'
      @service name: 'python-requests'
      @service name: 'python-arrow'

## Layout

    module.exports.push header: 'Shinken Broker # Layout', handler: ->
      {shinken} = @config.ryba
      @mkdir
        destination: "#{shinken.user.home}/share"
        uid: shinken.user.name
        gid: shinken.group.name
      @mkdir
        destination: "#{shinken.user.home}/doc"
        uid: shinken.user.name
        gid: shinken.group.name
      @chown
        destination: shinken.log_dir
        uid: shinken.user.name
        gid: shinken.group.name
      @execute
        cmd: 'shinken --init'
        unless_exists: '.shinken.ini'

## Additional Shinken Modules

    module.exports.push header: 'Shinken Broker # Modules', handler: ->
      {shinken, shinken:{broker}} = @config.ryba
      return unless Object.keys(broker.modules).length > 0
      @execute
        cmd: "su -l #{shinken.user.name} 'shinken --init'"
        unless_exists: "#{shinken.user.home}/.shinken.ini"
      installmod = (name, mod) =>  
        if mod.archive?
          @download
            destination: "#{mod.archive}.zip"
            source: mod.source
            cache_file: "#{mod.archive}.zip"
            unless_exec: "shinken inventory | grep #{name}"
          @extract
            source: "#{mod.archive}.zip"
            unless_exec: "shinken inventory | grep #{name}"
          @execute
            cmd: "shinken install --local #{mod.archive}"
            unless_exec: "shinken inventory | grep #{name}"
        else throw Error "Missing parameter: archive for broker.modules.#{name}"
        for subname, submod of mod.modules then installmod subname, submod
      for name, mod of broker.modules then installmod name, mod

It is not very clear if this must be executed on the broker or the arbiter node:
For now, distributed shinken is not ready and not tested.

Should also be natively corrected in the next shinken version. (actually 2.4)

      module.exports.push header: 'Shinken Broker # Fix ServiceGroups', handler: ->
        {shinken} = @config.ryba
        @write
          content: '        \'servicegroup_members\': StringProp(fill_brok=[\'full_status\']),' 
          append: '        \'servicegroup_name\': StringProp(fill_brok=[\'full_status\']),'
          destination: '/usr/lib/python2.7/site-packages/shinken/objects/servicegroup.py'

## Dependencies

    path = require 'path'
