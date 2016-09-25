
# Shinken Scheduler Install

    module.exports = header: 'Shinken Scheduler Install', handler: ->
      {shinken} = @config.ryba
      {scheduler} = @config.ryba.shinken

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
| shinken-scheduler | 7768  |  tcp  |   config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: scheduler.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Scheduler" }
        ]
        if: @config.iptables.action is 'start'

## Packages

      @service
        header: 'Packages'
        name: 'shinken-scheduler'

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
        for name, mod of scheduler.modules then installmod name, mod
