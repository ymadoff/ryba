# Docker ElasticSearch Install

    module.exports =  header: 'Docker ES # Install', handler: ->
      {swarm_manager,clusters,ssl} = @config.ryba.es_docker

      es_servers =  @hosts_with_module 'ryba/esdocker'
      for es_name,es of clusters then do (es_name,es) =>
  
        docker_services = {}
        docker_networks = {}
        
        
        @write_yaml
          header: 'elasticsearch'
          destination: "/etc/elasticsearch/#{es_name}/conf/elasticsearch.yml"
          content:es.config
          backup: true

        @write
          header: 'elasticsearch logging'
          destination: "/etc/elasticsearch/#{es_name}/conf/logging.yml"
          source: "#{__dirname}/resources/logging.yml"
          local_source: true
          backup: true


        @mkdir directory:"#{path}/#{es_name}",uid:'elasticsearch' for path in es.data_path
        @mkdir directory:"#{es.plugins_path}",uid:'elasticsearch'
        @mkdir directory:"#{es.plugins_path}/#{es.es_version}",uid:'elasticsearch'
        @mkdir directory:"#{es.logs_path}/#{es_name}",uid:'elasticsearch'
        @mkdir directory:"#{es.logs_path}/#{es_name}/logstash",uid:'elasticsearch'
        @mkdir directory:"/etc/elasticsearch/#{es_name}/scripts",uid:'elasticsearch'
        @mkdir directory:"/etc/elasticsearch/keytabs",uid:'elasticsearch'

        @each es.downloaded_urls,(options,callback) ->
          extract_target  = if options.value.indexOf("github") != -1  then "#{es.plugins_path}/#{es.es_version}/" else "#{es.plugins_path}/#{es.es_version}/#{options.key}"
          @call header: "Plugin #{options.key} installation...", ->
            @file.download
              cache_file: "/apps/Downloads/ryba/cache/#{options.key}.zip"
              source: options.value
              target: "#{es.plugins_path}/#{es.es_version}/#{options.key}.zip"
              uid: "elasticsearch"
              gid: "elasticsearch"
              shy: true
            @extract
              format: "zip"
              source: "#{es.plugins_path}/#{es.es_version}/#{options.key}.zip"
              target: extract_target
              shy: true
            es.volumes.push "#{es.plugins_path}/#{es.es_version}/#{options.key}:/usr/share/elasticsearch/plugins/#{options.key}"
            @remove "#{es.plugins_path}/#{es.es_version}/#{options.key}.zip", shy: true
          @then callback

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

          master_node = if es.master_nodes > 0
            "#{es.normalized_name}_master"
          else if es.master_data_nodes > 0
            "#{es.normalized_name}_master_data"


          es.volumes = [
            "/etc/elasticsearch/#{es_name}/conf/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml",
            "/etc/elasticsearch/#{es_name}/conf/logging.yml:/usr/share/elasticsearch/config/logging.yml",
            "/etc/elasticsearch/#{es_name}/scripts:/usr/share/elasticsearch/config/scripts",
            "#{es.logs_path}/#{es_name}:#{es.config['path.logs']}"

          ].concat es.volumes



          es.volumes.push "#{path}/#{es_name}/:#{path}" for path in es.data_path

          for type,es_node of es.nodes

            command = switch type
              when "master" then "elasticsearch -Des.discovery.zen.ping.unicast.hosts=#{master_node}_1 -Des.node.master=true -Des.node.data=false"
              when "master_data" then "elasticsearch -Des.discovery.zen.ping.unicast.hosts=#{master_node}_1 -Des.node.master=true -Des.node.data=true"
              when "data" then "elasticsearch -Des.discovery.zen.ping.unicast.hosts=#{master_node}_1 -Des.node.master=false -Des.node.data=true"


            docker_services[type] = {'environment' : [es.environment,"ES_HEAP_SIZE=#{es_node.heap_size}"] }
            service_def = 
              image : es.docker_es_image
              restart: "always"
              command: command
              networks: [es.network.name]
              user: "elasticsearch"
              volumes: es.volumes
              ports: es.ports
              mem_limit: if es_node.mem_limit? then es_node.mem_limit else es.default_mem
              # cpu_shares: if es_node.cpu_shares? then es_node.cpu_shares else es.default_cpu_shares

            if es_node.cpuset?
              service_def["cpuset"] = es_node.cpuset
            else 
              service_def["cpu_quota"] = if es_node.cpu_quota? then es_node.cpu_quota * 1000 else es.default_cpu_quota

            misc.merge docker_services[type], service_def

          if es.kibana?
            docker_services["#{es_name}_kibana"] = 
              image: es.kibana_image
              container_name: "#{es_name}_kibana"
              environment: ["ELASTICSEARCH_URL=http://#{master_node}_1:9200"]
              ports: ["#{es.kibana.port}:5601"]
              networks: [es.network.name]
          
          @write_yaml
            header: 'docker-compose'
            destination: "/etc/elasticsearch/#{es_name}/docker-compose.yml"
            content: {version:'2',services:docker_services,networks:docker_networks}
            backup: true

## Run docker compose file

          [docker_args,export_vars] = [
            {host:swarm_manager,tlsverify:" ",tlscacert:ssl.dest_cacert,tlscert:ssl.dest_cert,tlskey:ssl.dest_key},
            "export DOCKER_HOST=#{swarm_manager};export DOCKER_CERT_PATH=#{ssl.dest_dir};export DOCKER_TLS_VERIFY=1"
            ]
        
          @docker_status container:"#{master_node}_1", docker:docker_args
          
          for service,node of es.nodes then do (service,node) =>
            @execute
              cmd:"""
                #{export_vars}
                pushd /etc/elasticsearch/#{es_name}
                docker-compose --verbose scale #{service}=#{node.number}
              """
              unless: -> @status -1

          @execute
            cmd:"""
              #{export_vars}
              pushd /etc/elasticsearch/#{es_name}
              docker-compose --verbose up -d #{es_name}_kibana
            """
            if: -> es.kibana is true and @status (-1)


## Dependencies

    misc = require 'mecano/lib/misc'
