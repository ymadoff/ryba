
# Shinken Arbiter Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check

    module.exports.push name: 'Shinken Arbiter # Check Status', label_true: 'CHECKED', handler: ->
      @service
        srv_name: 'shinken'
        action: 'check'

    module.exports.push name: 'Shinken Arbiter # Check TCP', label_true: 'CHECKED', handler: ->
      {arbiter} = @config.ryba.shinken
      @execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{arbiter.config.port}"
    
    module.exports.push name: 'Shinken Arbiter # Check HTTP', label_true: 'CHECKED', handler: ->
      {arbiter} = @config.ryba.shinken  
      @execute
        cmd: "curl http://#{@config.host}:#{arbiter.config.port} | grep OK"
