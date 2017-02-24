
# Shinken Receiver Check

    module.exports = header: 'Shinken Receiver Check', label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {receiver} = @config.ryba.shinken

## TCP

      @system.execute
        header: 'TCP'
        cmd: "echo > /dev/tcp/#{@config.host}/#{receiver.config.port}"

## HTTP

      @system.execute
        header: 'HTTP'
        cmd: "curl http://#{@config.host}:#{receiver.config.port} | grep OK"
