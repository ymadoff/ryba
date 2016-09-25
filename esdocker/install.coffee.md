# Docker ElasticSearch Install

    module.exports =  header: 'Docker ES # Install', handler: ->
      {swarm_manager,clusters,ssl} = @config.ryba.es_docker

      es_servers =  @hosts_with_module 'ryba/esdocker'
      for es_name,es of clusters then do (es_name,es) =>
        docker_services = {}
        docker_networks = {}
        @file.yaml
          header: 'elasticsearch'
          target: "/etc/elasticsearch/#{es_name}/conf/elasticsearch.yml"
          content:es.config
        @file
          header: 'elasticsearch logging'
          target: "/etc/elasticsearch/#{es_name}/conf/logging.yml"
          source: "#{__dirname}/resources/logging.yml"
          local_source: true
        @file
          header: 'logstash'
          target: "/etc/elasticsearch/#{es_name}/logstash_config/logstash.conf"
          source: "#{__dirname}/resources/logstash.conf"
          local_source: true
          if: -> es.logstash?
        @mkdir directory:"#{path}/#{es_name}",uid:'elasticsearch' for path in es.data_path
        @mkdir directory:"/etc/elasticsearch/plugins",uid:'elasticsearch'
        @mkdir directory:"#{es.logs_path}/#{es_name}",uid:'elasticsearch'
        @mkdir directory:"#{es.logs_path}/#{es_name}/logstash",uid:'elasticsearch'

## SSL Certificate

        @file.download
          source: ssl.cacert
          target: ssl.dest_cacert
          mode: 0o0640
          shy: true
        @file.download
          source: ssl.cert
          target: ssl.dest_cert
          mode: 0o0640
          shy: true
        @file.download
          source: ssl.key
          target: ssl.dest_key
          mode: 0o0640
          shy: true

## Generate compose file

        if @config.host is es_servers[es_servers.length-1]
          #TODO create overlay network if the network does not exist
          docker_networks["#{es.network.name}"] = external: es.network.external
          volume = [
            "/etc/elasticsearch/#{es_name}/conf/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml",
            "/etc/elasticsearch/#{es_name}/conf/logging.yml:/usr/share/elasticsearch/config/logging.yml",
            "/etc/elasticsearch/plugins:/usr/share/elasticsearch/plugins",
            "#{es.logs_path}/#{es_name}:#{es.config['path.logs']}"
          ]
          volume.push "#{path}/#{es_name}/:#{path}" for path in es.data_path
          for es_node in es.nodes
            command = if es_node.master is true
              node_entity = "#{es_name}_master"
              docker_services[node_entity] = {'container_name': node_entity,'environment': ["ES_HEAP_SIZE=#{es.heap_size}"]}
              "elasticsearch -Des.node.master=true -Des.node.data=#{es_node.data}"
            else
              node_entity = "node"
              docker_services[node_entity] = {'environment' : es.environment }
              "elasticsearch -Des.discovery.zen.ping.unicast.hosts=#{es_name}_master -Des.node.master=false -Des.node.data=true"
            service_def = 
              image : es.es_image
              restart: "always"
              command: command
              networks: [es.network.name]
              user: "elasticsearch"
              volumes: volume
              ports: es.ports
              mem_limit: if es_node.mem_limit? then es_node.mem_limit else es.default_mem
              cpu_shares: if es_node.cpu_shares? then es_node.cpu_shares else es.default_cpu_shares
              cpu_quota: if es_node.cpu_quota? then es_node.cpu_quota * 1000 else es.default_cpu_quota
            if es_node.cpuset? then service_def["cpuset"] = es_node.cpuset
            misc.merge docker_services[node_entity], service_def

          if es.kibana is true
            docker_services["#{es_name}_kibana"] = 
              image: es.kibana_image
              container_name: "#{es_name}_kibana"
              environment: ["ELASTICSEARCH_URL=http://#{es_name}_master:9200"]
              ports: ["5601"]
              networks: [es.network.name]

          if es.logstash?
            # send events only to dedicated data nodes
            es_hosts = []
            es_hosts.push "\"#{es_name.replace('_','')}_node_#{i}:9200\"" for i in [1..es.number_of_containers - 1]            
            docker_services["#{es_name}_logstash"] = 
              image: es.logstash_image
              container_name: "#{es_name}_logstash"
              command: "logstash -f /config-dir/logstash.conf --log /log-dir"
              environment: [
                "TAG=#{es.logstash.tag}",
                "PORT=#{es.logstash.port}",
                "EVENT_TYPE=#{es.logstash.event_type}",
                "INDEX=#{es.logstash.index}",
                "DOC_TYPE=#{es.logstash.doc_type}",
                "ES_HOSTS=[#{es_hosts}]"
              ]
              ports: ["#{es.logstash.port}"]
              networks: [es.network.name]
              volumes: [
                "/etc/elasticsearch/#{es_name}/logstash_config:/config-dir",
                "#{es.logs_path}/#{es_name}/logstash:/log-dir"
                ]

          yaml_data = {version:'2',services:docker_services,networks:docker_networks}
          @file.yaml
            header: 'docker-compose'
            target: "/etc/elasticsearch/#{es_name}/docker-compose.yml"
            content:yaml_data

## Run docker compose file

          [docker_args,export_vars] = [
            {host:swarm_manager,tlsverify:" ",tlscacert:ssl.dest_cacert,tlscert:ssl.dest_cert,tlskey:ssl.dest_key},
            "export DOCKER_HOST=#{swarm_manager};export DOCKER_CERT_PATH=#{ssl.dest_dir};export DOCKER_TLS_VERIFY=1"
            ]

          @docker_status container:"#{es_name}_master", docker:docker_args

          @execute
            cmd:"""
              #{export_vars}
              pushd /etc/elasticsearch/#{es_name}
              docker-compose --verbose up -d #{es_name}_master
            """
            unless: -> @status -1

          @execute
            cmd:"""
              #{export_vars}
              pushd /etc/elasticsearch/#{es_name}
              docker-compose --verbose scale node=#{es.number_of_containers - 1}
            """
            if: -> @status -1

          @execute
            cmd:"""
              #{export_vars}
              pushd /etc/elasticsearch/#{es_name}
              docker-compose --verbose up -d #{es_name}_kibana
            """
            if: -> es.kibana is true and @status (-1)

          @execute
            cmd:"""
              #{export_vars}
              pushd /etc/elasticsearch/#{es_name}
              docker-compose --verbose up -d #{es_name}_logstash
            """
            if: -> es.logstash? and @status (-2)

## Dependencies

    misc = require 'mecano/lib/misc'
