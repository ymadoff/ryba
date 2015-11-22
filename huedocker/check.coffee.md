
# Hue Check

For now the check is only checking port state, and will succeed every by waiting
the server to start...

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/huedocker/wait'

## Check status of Hue server

  # TODO: Novembre 2015 check hue server by adding a user with the webservice.

    module.exports.push header: 'Hue Docker # Check', label_true: 'CHECKED', handler: ->
      {hue_docker} = @config.ryba
      @execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{hue_docker.port}"
