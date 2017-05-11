# Elasticsearch (Docker) Install

    module.exports =  header: 'Docker ES Install', handler: ->
      {swarm_manager,clusters,ssl,sysctl} = @config.ryba.es_docker
      elasticsearch = @config.ryba.elasticsearch

      @system.group elasticsearch.group
      @system.user elasticsearch.user

      @system.limits
        header: 'Ulimit'
        user: elasticsearch.user.name
      , elasticsearch.user.limits

      @call header: 'Kernel', (_, next) ->
        @system.execute
          if: Object.keys(sysctl).length
          cmd: 'sysctl -a'
          stdout: null
          shy: true
        , (err, _, content) ->
          throw err if err
          content = misc.ini.parse content
          properties = {}
          for k, v of sysctl
            v = "#{v}"
            properties[k] = v if content[k] isnt v
          return next null, false unless Object.keys(properties).length
          @fs.readFile '/etc/sysctl.conf', 'ascii', (err, config) =>
            current = misc.ini.parse config
            #merge properties from current config
            for k, v of current
              properties[k] = v if sysctl[k] isnt v
            @file
              header: 'Write Kernel Parameters'
              target: '/etc/sysctl.conf'
              content: misc.ini.stringify_single_key properties
              backup: true
              eof: true
            , (err) ->
              throw err if err
              properties = for k, v of properties then "#{k}='#{v}'"
              properties = properties.join ' '
              @system.execute
                cmd: "sysctl #{properties}"
              , next

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

      es_servers =  @contexts('ryba/esdocker').map((ctx) -> ctx.config.host)
      for es_name,es of clusters then do (es_name,es) =>
        docker_services = {}
        docker_networks = {}


        @file.yaml
          header: 'elasticsearch config file'
          target: "/etc/elasticsearch/#{es_name}/conf/elasticsearch.yml"
          content:es.config
          backup: true


        @file.render
          header: 'elasticsearch java policy'
          target: "/etc/elasticsearch/#{es_name}/conf/java.policy"
          source: "#{__dirname}/resources/java.policy.j2"
          local: true
          context: {es: logs_path: "#{es.logs_path}/#{es_name}"}
          backup: true

        @file
          header: 'elasticsearch logging'
          target: "/etc/elasticsearch/#{es_name}/conf/log4j2.properties"
          source: "#{__dirname}/resources/log4j2.properties"
          local: true
          backup: true

        @system.mkdir directory:"#{path}/#{es_name}",uid:'elasticsearch' for path in es.data_path
        @system.mkdir directory:"#{es.plugins_path}",uid:'elasticsearch'
        @system.mkdir directory:"#{es.plugins_path}/#{es.es_version}",uid:'elasticsearch'
        @system.mkdir directory:"#{es.logs_path}/#{es_name}",uid:'elasticsearch'
        @system.mkdir directory:"#{es.logs_path}/#{es_name}/logstash",uid:'elasticsearch'
        @system.mkdir directory:"/etc/elasticsearch/#{es_name}/scripts",uid:'elasticsearch'
        @system.mkdir directory:"/etc/elasticsearch/keytabs",uid:'elasticsearch'

        @each es.downloaded_urls,(options,callback) ->
          extract_target  = if options.value.indexOf("github") != -1  then "#{es.plugins_path}/#{es.es_version}/" else "#{es.plugins_path}/#{es.es_version}/#{options.key}"
          @call header: "Plugin #{options.key} installation...", ->
            @file.download
              cache_file: "./#{options.key}.zip"
              source: options.value
              target: "#{es.plugins_path}/#{es.es_version}/#{options.key}.zip"
              uid: "elasticsearch"
              gid: "elasticsearch"
              shy: true
            @tools.extract
              format: "zip"
              source: "#{es.plugins_path}/#{es.es_version}/#{options.key}.zip"
              target: extract_target
              shy: true
            es.volumes.push "#{es.plugins_path}/#{es.es_version}/#{options.key}:/usr/share/elasticsearch/plugins/#{options.key}"
            @system.remove "#{es.plugins_path}/#{es.es_version}/#{options.key}.zip", shy: true
          @then callback


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
            "/etc/elasticsearch/#{es_name}/conf/log4j2.properties:/usr/share/elasticsearch/config/log4j2.properties",
            "/etc/elasticsearch/#{es_name}/scripts:/usr/share/elasticsearch/config/scripts",
            "#{es.logs_path}/#{es_name}:#{es.config['path.logs']}",
            "/etc/elasticsearch/#{es_name}/conf/java.policy:/usr/share/elasticsearch/config/java.policy"

          ].concat es.volumes
          es.volumes.push "#{path}/#{es_name}/:#{path}" for path in es.data_path
          # es.volumes.push "#{es.plugins_path}/#{es.es_version}/#{plugin}:/usr/share/elasticsearch/plugins/#{plugin}" for plugin in es.plugins
          for type,es_node of es.nodes
            command = switch type
              when "master" then "elasticsearch -Ediscovery.zen.ping.unicast.hosts=#{master_node}_1 -Enode.master=true -Enode.data=false"
              when "master_data" then "elasticsearch -Ediscovery.zen.ping.unicast.hosts=#{master_node}_1 -Enode.master=true -Enode.data=true"
              when "data" then "elasticsearch -Ediscovery.zen.ping.unicast.hosts=#{master_node}_1 -Enode.master=false -Enode.data=true"
            docker_services[type] = {'environment' : [es.environment,"ES_JAVA_OPTS=-Xms#{es_node.heap_size} -Xmx#{es_node.heap_size} -Djava.security.policy=/usr/share/elasticsearch/config/java.policy","bootstrap.memory_lock=true"] }
            service_def = 
              image : es.docker_es_image
              restart: "always"
              command: command
              networks: [es.network.name]
              user: "elasticsearch"
              volumes: es.volumes
              ports: es.ports
              mem_limit: if es_node.mem_limit? then es_node.mem_limit else es.default_mem
              ulimits:  es.ulimits
              cap_add:  es.cap_add

            if es_node.cpuset?
              service_def["cpuset"] = es_node.cpuset
            else 
              service_def["cpu_quota"] = if es_node.cpu_quota? then es_node.cpu_quota * 1000 else es.default_cpu_quota
            misc.merge docker_services[type], service_def
          if es.kibana?
            docker_services["#{es_name}_kibana"] = 
              image: es.docker_kibana_image
              container_name: "#{es_name}_kibana"
              environment: ["ELASTICSEARCH_URL=http://#{master_node}_1:9200"]
              ports: ["#{es.kibana.port}:5601"]
              networks: [es.network.name]

          @file.yaml
            header: 'docker-compose'
            target: "/etc/elasticsearch/#{es_name}/docker-compose.yml"
            content: {version:'2',services:docker_services,networks:docker_networks}
            backup: true

## Run docker compose file

          [docker_args,export_vars] = [
            {host:swarm_manager,tlsverify:" ",tlscacert:ssl.dest_cacert,tlscert:ssl.dest_cert,tlskey:ssl.dest_key},
            "export DOCKER_HOST=#{swarm_manager};export DOCKER_CERT_PATH=#{ssl.dest_dir};export DOCKER_TLS_VERIFY=1"
            ]

          for service,node of es.nodes then do (service,node) =>
            @system.execute
              cmd:"""
              #{export_vars}
              pushd /etc/elasticsearch/#{es_name}
              docker-compose --verbose scale #{service}=#{node.number}
              """

          @system.execute
            cmd:"""
            #{export_vars}
            pushd /etc/elasticsearch/#{es_name}
            docker-compose --verbose up -d #{es_name}_kibana
            """
            if: -> es.kibana is true

## Dependencies

    misc = require 'nikita/lib/misc'
