
# Hue Status

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Hue Server Status

Check if hue_server container is running


    module.exports.push header: 'Hue Docker # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      {hue_docker} = @config.ryba
      @docker_status
        container: hue_docker.container
