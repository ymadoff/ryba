
# Elastic Search Config

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.configure = (ctx) ->
      {docker_es} = @config.ryba

      docker_es.es_clusters ?= {}
      docker_es.ssl ?= {}
      throw Error 'Required property "ryba.ssl.cacert" or "ryba.docker_es.ssl.cacert"' unless ctx.config.ryba.ssl?.cacert? or docker_es.ssl.cacert?
      throw Error 'Required property "ryba.ssl.cert"' unless ctx.config.ryba.ssl?.cert? or docker_es.ssl.cert?
      throw Error 'Required property "ryba.ssl.key"' unless ctx.config.ryba.ssl?.key? or docker_es.ssl.key?

      docker_es.ssl.cacert ?= ctx.config.ryba.ssl.cacert
      docker_es.ssl.cert ?= ctx.config.ryba.ssl.cert
      docker_es.ssl.key ?= ctx.config.ryba.ssl.key

      docker_es.ssl.dest_dir ?= "/etc/docker/certs.d"
      docker_es.ssl.dest_cacert = "#{docker_es.ssl.dest_dir}/ca.pem"
      docker_es.ssl.dest_cert = "#{docker_es.ssl.dest_dir}/cert.pem"
      docker_es.ssl.dest_key = "#{docker_es.ssl.dest_dir}/key.pem"

      for es_name,es of docker_es.es_clusters
        #Docker:
        es.docker_es_image ?= "elasticsearch"
        es.docker_kibana_image ?= "kibana"
        #Cluster
        es.number_of_containers ?= @hosts_with_module('ryba/docker-es').length
        es.number_of_shards ?= es.number_of_containers
        es.number_of_replicas ?= 1
        es.data_path ?= ["/data/1","/data/2","/data/3"]
        es.environment = ["affinity:container!=**#{es_name}_master","affinity:container!=*#{es_name}_node*"]
        throw Error 'Required property "nodes"' unless es.nodes?
        throw Error 'Required property "network" and network.external' unless es.network?

        #TODO create overlay network if the network does not exist
        #For now We assume that the network is already created by docker network create
        es.network.external = true
        es.default_mem = '2g'
        # cpu quota 20%
        es.default_cpu_quota = 20000

    module.exports.push commands: 'install', modules: [
      'ryba/esdocker/install'
    ]

