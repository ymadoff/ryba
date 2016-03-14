
# Shinken Reactionner Install

    module.exports = header: 'Shinken Reactionner Install', handler: ->
      {shinken} = @config.ryba
      {reactionner, user} = @config.ryba.shinken

## SSH

      @call
        header: 'SSH'
        if: -> @config.ryba.shinken.reactionner.ssh?.private_key? and @config.ryba.shinken.reactionner.ssh?.public_key?
        handler: ->
          @mkdir
            destination: "#{user.home}/.ssh"
            mode: 0o700
            uid: user.name
            gid: user.gid
          @write
            destination: "#{user.home}/.ssh/id_rsa"
            content: reactionner.ssh.private_key
            eof: true
            mode: 0o600
            uid: user.name
            gid: user.gid
          @write
            destination: "#{user.home}/.ssh/id_rsa.pub"
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
      @iptables
        header: 'IPTables'
        rules: rules
        if: @config.iptables.action is 'start'

## Packages

      @service
        header: 'Packages'
        name: 'shinken-reactionner'

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
        for name, mod of reactionner.modules
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
          else throw Error "Missing parameter: archive for reactionner.modules.#{name}"
