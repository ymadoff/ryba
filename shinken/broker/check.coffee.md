
# Shinken Broker Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check

    module.exports.push header: 'Shinken Broker # Check TCP', label_true: 'CHECKED', handler: ->
      {broker} = @config.ryba.shinken
      @execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{broker.config.port}"
      
    module.exports.push header: 'Shinken Broker # Check Status', label_true: 'CHECKED', handler: ->
      {broker} = @config.ryba.shinken
      @execute
        cmd: "curl http://#{@config.host}:#{broker.config.port} | grep OK"
