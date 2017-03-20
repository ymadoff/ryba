# ActiveMQ Prepare

Download the ActiveMQ Container

    module.exports =
      header: 'ActiveMQ'
      timeout: -1
      if: -> @contexts('ryba/activemq/server')[0]?.config.host is @config.host
      handler: ->
        {activemq} = @config
        @docker.pull
          tag: 'rmohr/activemq'
          version: activemq.version
        @docker.save
          image: "rmohr/activemq:#{activemq.version}"
          output: "#{@config.mecano.cache_dir}/activemq.tar"
