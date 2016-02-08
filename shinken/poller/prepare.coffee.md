
# Poller Executor Build

    module.exports = []
    module.exports.push 'masson/bootstrap/log'

## Build Prepare

    module.exports.push header: 'Shinken Poller Executor # Build Prepare', timeout: -1,  handler: ->
      {poller} = @config.ryba.shinken
      @docker_build
        tag: 'ryba/shinken-poller-executor'
        file: "#{__dirname}/resources/Dockerfile"
      @docker_save
        image: 'ryba/shinken-poller-executor'
        destination: "#{@config.mecano.cache_dir or '.'}/shinken-poller-executor.tar"