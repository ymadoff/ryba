
# Elastic Search Config

    module.exports = handler: ->
      docker_es = @config.ryba.docker_es ?= {}

      docker_es.es_clusters ?= {}
      docker_es.ssl ?= {}
      throw Error 'Required property "ryba.ssl.cacert" or "ryba.docker_es.ssl.cacert"' unless @config.ryba.ssl?.cacert? or docker_es.ssl.cacert?
      throw Error 'Required property "ryba.ssl.cert"' unless @config.ryba.ssl?.cert? or docker_es.ssl.cert?
      throw Error 'Required property "ryba.ssl.key"' unless @config.ryba.ssl?.key? or docker_es.ssl.key?

      docker_es.ssl.cacert ?= @config.ryba.ssl.cacert
      docker_es.ssl.cert ?= @config.ryba.ssl.cert
      docker_es.ssl.key ?= @config.ryba.ssl.key

      docker_es.ssl.dest_dir ?= "/etc/docker/certs.d"
      docker_es.ssl.dest_cacert = "#{docker_es.ssl.dest_dir}/ca.pem"
      docker_es.ssl.dest_cert = "#{docker_es.ssl.dest_dir}/cert.pem"
      docker_es.ssl.dest_key = "#{docker_es.ssl.dest_dir}/key.pem"

      docker_es.graphite ?= @config.metrics_sinks.graphite = {}

      for es_name,es of docker_es.es_clusters 
      	delete docker_es.es_clusters[es_name] unless es.only

      # console.log docker_es.es_clusters
      for es_name,es of docker_es.es_clusters
        #Docker:
        es.docker_es_image ?= "elasticsearch"
        es.docker_kibana_image ?= "kibana"
        es.docker_logstash_image ?= "logstash"
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
          throw Error 'Required property "graphite.host"' unless docker_es.graphite.host?
          throw Error 'Required property "graphite.port"' unless docker_es.graphite.port?

          es.config["metrics.graphite.host"] = docker_es.graphite.host
          es.config["metrics.graphite.port"] = docker_es.graphite.port
          es.config["metrics.graphite.every"] = docker_es.graphite.every ?= "10s"
          es.config["metrics.graphite.prefix"] = "es.#{es_name}.${HOSTNAME}"
          
          

