
# Elastic Search Config

    module.exports = handler: ->
      es_docker = @config.ryba.es_docker ?= {}

      es_docker.clusters ?= {}
      es_docker.ssl ?= {}
      throw Error 'Required property "ryba.ssl.cacert" or "ryba.es_docker.ssl.cacert"' unless @config.ryba.ssl?.cacert? or es_docker.ssl.cacert?
      throw Error 'Required property "ryba.ssl.cert"' unless @config.ryba.ssl?.cert? or es_docker.ssl.cert?
      throw Error 'Required property "ryba.ssl.key"' unless @config.ryba.ssl?.key? or es_docker.ssl.key?

      es_docker.ssl.cacert ?= @config.ryba.ssl.cacert
      es_docker.ssl.cert ?= @config.ryba.ssl.cert
      es_docker.ssl.key ?= @config.ryba.ssl.key

      es_docker.ssl.dest_dir ?= "/etc/docker/certs.d"
      es_docker.ssl.dest_cacert = "#{es_docker.ssl.dest_dir}/ca.pem"
      es_docker.ssl.dest_cert = "#{es_docker.ssl.dest_dir}/cert.pem"
      es_docker.ssl.dest_key = "#{es_docker.ssl.dest_dir}/key.pem"

      es_docker.graphite ?= @config.metrics_sinks.graphite = {}

      for es_name,es of es_docker.clusters 
      	delete es_docker.clusters[es_name] unless es.only

      # console.log es_docker.clusters
      for es_name,es of es_docker.clusters
        #Docker:
        es.es_image ?= "elasticsearch"
        es.kibana_image ?= "kibana"
        es.logstash_image ?= "logstash"
        #Cluster
        es.number_of_containers ?= @hosts_with_module('ryba/docker-es').length
        es.number_of_shards ?= es.number_of_containers
        es.number_of_replicas ?= 1
        es.data_path ?= ["/data/1","/data/2","/data/3","/data/4","/data/5","/data/6","/data/7","/data/8"]
        es.logs_path ?= "/var/hadoop_log/docker/es"
        es.default_mem = '2g'
        # cpu quota 100% et 4 cpu cores
        es.default_cpu_shares = 4
        es.default_cpu_quota = 100000
        es.heap_size ?= '1g'
        es.environment = ["affinity:container!=**#{es_name}_master","affinity:container!=*#{es_name}_node*","ES_HEAP_SIZE=#{es.heap_size}"]
        throw Error 'Required property "ports"' unless es.ports?
       	if es.ports instanceof Array
          port_mapping = port.split(":").length > 1 for port in es.ports
          throw Error 'property "ports" must be an array of ports mapping ["9200:port1","9300:port2"]' unless port_mapping is true
        else
          throw Error 'property "ports" must be an array of ports mapping ["9200:port1","9300:port2"]'

        throw Error 'Required property "nodes"' unless es.nodes?
        throw Error 'Required property "network" and network.external' unless es.network?

        # console.log "cluseter #{es_name} ports: #{es.ports}"
        #TODO create overlay network if the network does not exist
        #For now We assume that the network is already created by docker network create
        es.network.external = true
        if es.logstash?
          throw Error 'Required property "logstash.port"' unless es.logstash.port?
          throw Error 'Required property "logstash.index"' unless es.logstash.index?
          throw Error 'Required property "logstash.doc_type"' unless es.logstash.doc_type?

          es.logstash.tag ?= 'TAG1'
          es.logstash.event_type ?= 'app_logs'

        #ES Config file
        es.config = {}
        es.config["bootstrap.mlockall"] = true
        es.config["network.host"] = "0.0.0.0"
        es.config["cluster.name"] = "#{es_name}"
        es.config["cluster.number_of_shards"] = es.number_of_shards
        es.config["cluster.number_of_replicas"] = es.number_of_replicas
        es.config["path.data"] = "#{es.data_path}"
        es.config["path.logs"] = "/var/log/elasticsearch"
        if es.graphite?
          throw Error 'Required property "graphite.host"' unless es_docker.graphite.host?
          throw Error 'Required property "graphite.port"' unless es_docker.graphite.port?

          es.config["metrics.graphite.host"] = es_docker.graphite.host
          es.config["metrics.graphite.port"] = es_docker.graphite.port
          es.config["metrics.graphite.every"] = es_docker.graphite.every ?= "10s"
          es.config["metrics.graphite.prefix"] = "es.#{es_name}.${HOSTNAME}"
          
          

