
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

## Additional Modules

      @call header: 'Modules', handler: ->
        installmod = (name, mod) =>
          @call unless_exec: "shinken inventory | grep #{name}", handler: ->
            @file.download
              target: "#{shinken.build_dir}/#{mod.archive}.zip"
              source: mod.source
              cache_file: "#{mod.archive}.zip"
              unless_exec: "shinken inventory | grep #{name}"
              shy: true
            @extract
              source: "#{shinken.build_dir}/#{mod.archive}.zip"
              shy: true
            @execute
              cmd: "shinken install --local #{shinken.build_dir}/#{mod.archive}"
            @execute
              cmd: "rm -rf #{shinken.build_dir}"
              shy: true
          for subname, submod of mod.modules then installmod subname, submod
        for name, mod of receiver.modules then installmod name, mod

