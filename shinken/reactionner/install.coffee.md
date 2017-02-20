
# Shinken Reactionner Install

    module.exports = header: 'Shinken Reactionner Install', handler: ->
      {shinken} = @config.ryba
      {reactionner, user} = @config.ryba.shinken

## SSH

      @call
        header: 'SSH'
        if: -> @config.ryba.shinken.reactionner.ssh?.private_key? and @config.ryba.shinken.reactionner.ssh?.public_key?
        handler: ->
          @system.mkdir
            target: "#{user.home}/.ssh"
            mode: 0o700
            uid: user.name
            gid: user.gid
          @file
            target: "#{user.home}/.ssh/id_rsa"
            content: reactionner.ssh.private_key
            eof: true
            mode: 0o600
            uid: user.name
            gid: user.gid
          @file
            target: "#{user.home}/.ssh/id_rsa.pub"
            content: reactionner.ssh.public_key
            eof: true
            mode: 0o644
            uid: user.name
            gid: user.gid

## IPTables

| Service             | Port  | Proto | Parameter        |
|---------------------|-------|-------|------------------|
| shinken-reactionner | 7769  |  tcp  |    config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      rules = [{ chain: 'INPUT', jump: 'ACCEPT', dport: reactionner.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Reactionner" }]
      for name, mod of reactionner.modules
        if mod.config?.port?
          rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: mod.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Reactionner #{name}" }
      @tools.iptables
        header: 'IPTables'
        rules: rules
        if: @config.iptables.action is 'start'

## Packages

      @service
        header: 'Packages'
        name: 'shinken-reactionner'

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
        for name, mod of reactionner.modules then installmod name, mod
