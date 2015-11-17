
# Wait hue server

Wait for hue server to have executed all start up script, and container running.
This script has been written to be able to wait several hue server. hue HA will
be released soon.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'Hue Docker # Wait', timeout: -1, label_true: 'READY', handler: ->
      @wait_connect
        servers: for hue_ in @contexts 'ryba/huedocker', require('./index').configure
          host: hue_.config.host
          port: hue_.config.ryba.hue_docker.port
