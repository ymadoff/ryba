
# SolrCloud Layout

    module.exports = headler: 'SolrCloud Atlas Layout', handler: (options) ->
      {cluster_config} = options
      {solr} = @config.ryba
      atlas =  @contexts('ryba/atlas')[0].config.ryba.atlas
      numShards = replicationFactor = cluster_config.hosts.length
      dir = "#{cluster_config.atlas_collection_dir}"
      @file.download
        source: "#{__dirname}/resources/solr/lang/stopwords_en.txt"
        target: "#{dir}/lang/stopwords_en.txt"
      @file.download
        source: "#{__dirname}/resources/solr/currency.xml"
        target: "#{dir}/currency.xml"
      @file.download
        source: "#{__dirname}/resources/solr/protwords.txt"
        target: "#{dir}/protwords.txt"
      @file.download
        source: "#{__dirname}/resources/solr/schema.xml"
        target: "#{dir}/schema.xml"
      @file.download
        source: "#{__dirname}/resources/solr/solrconfig.xml"
        target: "#{dir}/solrconfig.xml"
      @file.download
        source: "#{__dirname}/resources/solr/stopwords.txt"
        target: "#{dir}/stopwords.txt"
      @file.download
        source: "#{__dirname}/resources/solr/synonyms.txt"
        target: "#{dir}/synonyms.txt"

## Create Atlas Collection in Solr

      @call
        if: -> @config.host is cluster_config.master
      , ->
        @call
          if: atlas.solr_type is 'cloud_docker'
          header:'Create Atlas Collection Collection (cloud_docker)'
          handler: ->
            @connection.wait
              host: cluster_config['master']
              port: cluster_config['port']
            @docker.exec
              container: cluster_config.master_container_runtime_name
              cmd: "/usr/solr-cloud/current/bin/solr healthcheck -c vertex_index"
              code_skipped: [1,126]
            @docker.exec
              unless: -> @status -1
              header: 'Create vertex_index collection'
              container: cluster_config.master_container_runtime_name
              cmd: """
                /usr/solr-cloud/current/bin/solr create_collection -c vertex_index \
                -shards #{@contexts('ryba/solr/cloud_docker').length}  \
                -replicationFactor #{@contexts('ryba/solr/cloud_docker').length} \
                -d /atlas_solr
              """
            @docker.exec
              container: cluster_config.master_container_runtime_name
              cmd: "/usr/solr-cloud/current/bin/solr healthcheck -c edge_index"
              code_skipped: [1,126]
            @docker.exec
              unless: -> @status -1
              header: 'Create edge_index collection'
              container: cluster_config.master_container_runtime_name
              cmd: """
                /usr/solr-cloud/current/bin/solr create_collection -c edge_index \
                -shards #{@contexts('ryba/solr/cloud_docker').length}  \
                -replicationFactor #{@contexts('ryba/solr/cloud_docker').length} \
                -d /atlas_solr
              """
            @docker.exec
              container: cluster_config.master_container_runtime_name
              cmd: "/usr/solr-cloud/current/bin/solr healthcheck -c fulltext_index"
              code_skipped: [1,126]
            @docker.exec
              unless: -> @status -1
              header: 'Create fulltext_index collection'
              container: cluster_config.master_container_runtime_name
              cmd: """
                /usr/solr-cloud/current/bin/solr create_collection -c fulltext_index \
                -shards #{@contexts('ryba/solr/cloud_docker').length}  \
                -replicationFactor #{@contexts('ryba/solr/cloud_docker').length} \
                -d /atlas_solr
              """

        @call
          if: atlas.solr_type is 'cloud' and cluster_config.hosts[0] is @config.host
          header:'Create Atlas Collection Collection (cloud)'
          handler: ->
            @connection.wait
              servers: for host in cluster_config.hosts
                host: host
                port: @contexts('ryba/solr/cloud')[0].config.ryba.solr.cloud.port
            @system.execute
              unless_exec: "/usr/solr-cloud/current/bin/solr healthcheck -c vertex_index"
              cmd: """
                /usr/solr-cloud/current/bin/solr create_collection -c vertex_index \
                -shards #{cluster_config.hosts.length}  \
                -replicationFactor #{cluster_config.hosts.length} \
                -d #{cluster_config.atlas_collection_dir}
              """
            @system.execute
              unless_exec: "/usr/solr-cloud/current/bin/solr healthcheck -c edge_index"
              cmd: """
                /usr/solr-cloud/current/bin/solr create_collection -c edge_index \
                -shards #{cluster_config.hosts.length}  \
                -replicationFactor #{cluster_config.hosts.length} \
                -d #{cluster_config.atlas_collection_dir}
              """
            @system.execute
              unless_exec: "/usr/solr-cloud/current/bin/solr healthcheck -c fulltext_index"
              cmd: """
                /usr/solr-cloud/current/bin/solr create_collection -c fulltext_index \
                -shards #{cluster_config.hosts.length}  \
                -replicationFactor #{cluster_config.hosts.length} \
                -d #{cluster_config.atlas_collection_dir}
              """
