
# Poller Executor Build

    module.exports = header: 'Shinken Poller Prepare', timeout: -1,  handler: ->
      {shinken} = @config.ryba
      if @contexts('ryba/shinken/poller')[0].config.host is @config.host

## Build Container

        @render
          header: 'Render Dockerfile'
          destination: "#{@config.mecano.cache_dir or '.'}/build/Dockerfile"
          source: "#{__dirname}/resources/Dockerfile.j2"
          local_source: true
          context: @config.ryba

        @write
          header: 'Write Java Profile'
          destination: "#{@config.mecano.cache_dir or '.'}/build/java.sh"
          content: """
          export JAVA_HOME=/usr/java/default
          export PATH=/usr/java/default/bin:$PATH
          """

        @docker_build
          header: 'Build Container'
          image: 'ryba/shinken-poller-executor'
          file: "#{@config.mecano.cache_dir or '.'}/build/Dockerfile"
          cwd: shinken.poller.executor.build_dir

## Save image

        @docker_save
          header: 'Save Container'
          image: 'ryba/shinken-poller-executor'
          destination: "#{@config.mecano.cache_dir or '.'}/shinken-poller-executor.tar"
