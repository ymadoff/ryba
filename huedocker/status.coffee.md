
# Hue Status

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Hue Server Status

Check if hue_server container is running


    module.exports.push name: 'Hue Docker # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      {hue} = @config.ryba
      @execute
        cmd: "docker ps  | grep hue_server"
        if_exec: "docker ps  | grep hue_server"
