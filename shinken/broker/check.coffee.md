
# Shinken Broker Check

    module.exports = header: 'Shinken Broker Check', label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {broker} = @config.ryba.shinken

## TCP

      @system.execute
        header: 'TCP'
        cmd: "echo > /dev/tcp/#{@config.host}/#{broker.config.port}"

## HTTP

      @system.execute
        header: 'HTTP'
        cmd: "curl http://#{@config.host}:#{broker.config.port} | grep OK"
