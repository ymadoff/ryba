# Docker ElasticSearch Install

    module.exports = []
    module.exports.push 'masson/bootstrap'


    module.exports.push header: 'Docker ES # Env', handler: ->
      {swarm_manager,es_clusters,ssl} = @config.ryba.docker_es

      es_servers =  @hosts_with_module 'ryba/esdocker'
      for es_name,es of es_clusters then do (es_name,es) =>
  Generate elasticsearch config file per cluster
  
        docker_services = {}
        docker_networks = {}
        writes = [
          match: /^.*cluster.name: .*/m
          replace: "cluster.name: \"#{es_name}\" # RYBA CONF `elasticsearch.cluster.name`, DON'T OVERWRITE"
        ,
          match: /^.*index.number_of_shards: .*/m
          replace: "index.number_of_shards: #{es.number_of_shards} # RYBA CONF `elasticsearch.number_of_shards`, DON'T OVERWRITE"
          append: true
        ,
          match: /^.*index.number_of_replicas: .*/m
          replace: "index.number_of_replicas: #{es.number_of_replicas} # RYBA CONF `elasticsearch.number_of_replicas`, DON'T OVERWRITE"
          append: true
        ,
          match: /^.*path.data: .*/m
          replace: "path.data: [#{es.data_path}] # RYBA CONF `elasticsearch.data_path`, DON'T OVERWRITE"
          append: true
        ]

        @write
          header: 'elasticsearch'
          destination: "/etc/elasticsearch/#{es_name}/conf/elasticsearch.yml"
          source: "#{__dirname}/resources/elasticsearch.yml"
          write: writes
          local_source: true

        @mkdir directory:"#{path}/#{es_name}",uid:'elasticsearch' for path in es.data_path

## SSL Certificate
        
        @download
          source: ssl.cacert
          destination: ssl.dest_cacert
          mode: 0o0640
          shy: true
        @download
          source: ssl.cert
          destination: ssl.dest_cert
          mode: 0o0640
          shy: true
        @download
          source: ssl.key
          destination: ssl.dest_key
          mode: 0o0640
          shy: true

## Generate compose file
      
        if @config.host is es_servers[es_servers.length-1]
          #TODO create overlay network if the network does not exist
          docker_networks["#{es.network.name}"] = external: es.network.external
          volume = ["/etc/elasticsearch/#{es_name}/conf/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml"]
          volume.push "#{path}/#{es_name}/:#{path}" for path in es.data_path

          for es_node in es.nodes
            command = if es_node.master is true
              node_entity = "#{es_name}_master"
              docker_services[node_entity] = {'container_name': node_entity}
              docker_services[node_entity]['ports'] = if es_node.ports? then es_node.ports else ["9200","9300"]
              "elasticsearch -Des.node.master=true -Des.node.data=#{es_node.data}"
            else
              node_entity = "#{es_name}_node"
              docker_services[node_entity] = {'environment' : es.environment }
              "elasticsearch -Des.discovery.zen.ping.unicast.hosts=#{es_name}_master -Des.node.master=false -Des.node.data=true"

            service_def = 
              image : es.docker_es_image
              restart: "always"
              command: command
              networks: [es.network.name]
              user: "elasticsearch"
              volumes: volume
              cpu_quota: if es_node.cpu_quota? then es_node.cpu_quota * 1000 else es.default_cpu_quota
              mem_limit: if es_node.mem_limit? then es_node.mem_limit else es.default_mem
            
            misc.merge docker_services[node_entity], service_def

          if es.kibana is true
            docker_services["#{es_name}_kibana"] = 
              image: es.docker_kibana_image
              container_name: "#{es_name}_kibana"
              environment: ["ELASTICSEARCH_URL=http://#{es_name}_master:9200"]
              ports: ["5601"]
              networks: [es.network.name]
    
          yaml_data = {version:'2',services:docker_services,networks:docker_networks}
          @write_yaml
            header: 'docker-compose'
            destination: "/etc/elasticsearch/#{es_name}/docker-compose.yml"
            content:yaml_data

## Run docker compose file

          [docker_args,export_vars] = [
            {host:swarm_manager,tlsverify:'',tlscacert:ssl.dest_cacert,tlscert:ssl.dest_cert,tlskey:ssl.dest_key},
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
              docker-compose --verbose scale #{es_name}_node=#{es.number_of_containers - 1}
            """
            if: -> @status -1

          @execute
            cmd:"""
              #{export_vars}
              pushd /etc/elasticsearch/#{es_name}
              docker-compose --verbose up -d #{es_name}_kibana
            """
            if: -> es.kibana is true and @status (-1)
          


## Dependencies

    misc = require 'mecano/lib/misc'
  