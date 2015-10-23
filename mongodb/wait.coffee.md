
# MongoDB Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'MongoDB # Wait', label_true: 'READY', timeout: -1, handler: ->
      @wait_connect
        servers:
          host: @config.host
          port: @config.ryba.mongodb.srv_config.port
