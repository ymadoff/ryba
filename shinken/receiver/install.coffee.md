
# Shinken Receiver Install

    module.exports = header: 'Shinken Receiver Install', handler: ->
      {shinken} = @config.ryba
      {receiver} = @config.ryba.shinken

## IPTables

| Service          | Port  | Proto | Parameter       |
|------------------|-------|-------|-----------------|
| shinken-receiver | 7773  |  tcp  |   config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: receiver.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Receiver" }
        ]
        if: @config.iptables.action is 'start'

## Packages

      @service
        header: 'Packages'
        name: 'shinken-receiver'

## Layout

      @call header: 'Layout', handler: ->
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

## Additional Modules

      @call header: 'Modules', handler: ->
        for name, mod of receiver.modules
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
          else throw Error "Missing parameter: archive for receiver.modules.#{name}"
