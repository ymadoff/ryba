
# Shinken Reactionner Check

    module.exports = header: 'Shinken Reactionner Check', label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {reactionner} = @config.ryba.shinken

## TCP

      @system.execute
        header: 'TCP'
        cmd: "echo > /dev/tcp/#{@config.host}/#{reactionner.config.port}"

## HTTP

      @system.execute
        header: 'HTTP'
        cmd: "curl http://#{@config.host}:#{reactionner.config.port} | grep OK"
