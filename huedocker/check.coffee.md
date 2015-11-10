
# Hue Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/huedocker/wait'

## Check status of Hue server


    module.exports.push name: 'Hue Docker # Check', label_true: 'CHECKED', handler: ->
      {hue} = @config.ryba
      @execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{hue.port}"
