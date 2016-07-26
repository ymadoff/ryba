
# Falcon Server Check

    module.exports = header: 'Falcon Server Check', handler: ->
      {falcon} = @config.ryba
      {hostname, port} = url.parse falcon.runtime['prism.falcon.local.endpoint']
      @assert
        host: hostname
        port: port

## Dependencies

    url = require 'url'
