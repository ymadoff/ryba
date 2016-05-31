
# Poller Executor Build

    module.exports = header: 'Shinken Poller Prepare', timeout: -1,  handler: ->
      {shinken} = @config.ryba

## Build Container

      @render
        header: 'Render Dockerfile'
        destination: "#{@config.mecano.cache_dir or '.'}/Dockerfile"
        source: "#{__dirname}/resources/Dockerfile.j2"
        local_source: true
        context: @config.ryba

      @docker_build
        header: 'Build Container'
        image: 'ryba/shinken-poller-executor'
        file: "#{@config.mecano.cache_dir or '.'}/Dockerfile"

## Save image

      @docker_save
        header: 'Save Container'
        image: 'ryba/shinken-poller-executor'
        destination: "#{@config.mecano.cache_dir or '.'}/shinken-poller-executor.tar"
