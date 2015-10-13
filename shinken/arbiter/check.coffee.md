
# Shinken Arbiter Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check

    module.exports.push name: 'Shinken Arbiter # Check Configuration', label_true: 'CHECKED', handler: ->
      @service
        srv_name: 'shinken'
        action: 'check'

    module.exports.push name: 'Shinken Arbiter # Check TCP', label_true: 'CHECKED', handler: ->
      {arbiter} = @config.ryba.shinken
      @execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{arbiter.config.port}"
      @execute
        cmd: "curl http://#{@config.host}:#{arbiter.config.port} | grep OK"
