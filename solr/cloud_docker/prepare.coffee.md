  
# Solr Cloud Docker Prepare
Build container and save it.
  
    module.exports = 
      header: 'Solr Cloud Docker Prepare'
      timeout: -1
      if: -> @contexts('ryba/solr/cloud_docker')[0]?.config.host is @config.host
      handler: ->
        {solr} = @config.ryba
        @mkdir
          target: solr.cloud_docker.build.dir
        @mkdir
          target: "#{solr.cloud_docker.build.dir}/build"
        @render
          source: "#{__dirname}/../resources/cloud_docker/docker_entrypoint.sh"
          target: "#{solr.cloud_docker.build.dir}/build/docker_entrypoint.sh"
          context: @config
        @render
          source: "#{__dirname}/../resources/cloud_docker/Dockerfile"
          target: "#{solr.cloud_docker.build.dir}/build/Dockerfile"
          context: @config
        @docker.build
          image: "#{solr.cloud_docker.build.image}:#{solr.cloud_docker.version }"
          file: "#{solr.cloud_docker.build.dir}/build/Dockerfile"
        @docker.save
          image: "#{solr.cloud_docker.build.image}:#{solr.cloud_docker.version }"
          output: "#{solr.cloud_docker.build.dir}/#{solr.cloud_docker.build.tar}"
        
