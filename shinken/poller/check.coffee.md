
# Shinken Poller Check

    module.exports = header: 'Shinken Poller Check', label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {poller} = @config.ryba.shinken

## TCP

      @execute
        header: 'TCP'
        cmd: "echo > /dev/tcp/#{@config.host}/#{poller.config.port}"

## HTTP

      @execute
        header: 'HTTP'
        cmd: "curl http://#{@config.host}:#{poller.config.port} | grep OK"
