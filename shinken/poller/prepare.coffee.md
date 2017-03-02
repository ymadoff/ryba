
# Poller Executor Build

    module.exports = header: 'Shinken Poller Prepare', timeout: -1,  handler: ->
      {shinken} = @config.ryba
      if @contexts('ryba/shinken/poller')[0].config.host is @config.host

## Build Container

        @file.render
          header: 'Render Dockerfile'
          target: "#{@config.mecano.cache_dir or '.'}/build/Dockerfile"
          source: "#{__dirname}/resources/Dockerfile.j2"
          local: true
          context: @config.ryba
        @file
          header: 'Write Java Profile'
          target: "#{@config.mecano.cache_dir or '.'}/build/java.sh"
          content: """
          export JAVA_HOME=/usr/java/default
          export PATH=/usr/java/default/bin:$PATH
          """
        @file
          header: 'Write RSA Private Key'
          target: "#{@config.mecano.cache_dir or '.'}/build/id_rsa"
          content: @config.connection.private_key
        @file
          header: 'Write RSA Public Key'
          target: "#{@config.mecano.cache_dir or '.'}/build/id_rsa.pub"
          content: @config.connection.public_key
        @docker_build
          header: 'Build Container'
          image: 'ryba/shinken-poller-executor'
          file: "#{@config.mecano.cache_dir or '.'}/build/Dockerfile"
          cwd: shinken.poller.executor.build_dir

## Save image

        @docker_save
          header: 'Save Container'
          image: 'ryba/shinken-poller-executor'
          target: "#{@config.mecano.cache_dir or '.'}/shinken-poller-executor.tar"
