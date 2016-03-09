
# Shinken Scheduler Check

    module.exports = header: 'Shinken Scheduler Check', label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {scheduler} = @config.ryba.shinken

## TCP

      @execute
        header: 'TCP'
        cmd: "echo > /dev/tcp/#{@config.host}/#{scheduler.config.port}"

## HTTP

      @execute
        header: 'HTTP'
        cmd: "curl http://#{@config.host}:#{scheduler.config.port} | grep OK"
