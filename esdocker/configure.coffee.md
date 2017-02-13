
# Elasticsearch (Docker) Configuration

## Example

```
    es_docker:
      swarm_manager: "tcp://noeyy6vf.noe.edf.fr:3376"
      graphite:
        host: "noeyy6z1.noe.edf.fr"
        port: 2003
        every: "10s"
      clusters:
        "es_re7":
          es_version: "2.3.3"
          number_of_shards: 1
          number_of_replicas: 1
          number_of_containers: 1
          data_path: ["/data/1","/data/2","/data/3","/data/4","/data/5","/data/6"]
          logs_path: "/var/hadoop_log/docker/es"
          plugins_path: "/etc/elasticsearch/plugins"
          ports: ["9200:9200","9200:9300"]
          nodes:
            master_data:
              number: 2
              cpuset: "1-8",
              mem_limit: '56g'
              heap_size: '20g'
            data:
              number: 3
              cpuset: "1-8",
              mem_limit: '56g'
              heap_size: '20g'
            master:
              number: 2
              cpuset: "1-8",
              mem_limit: '56g'
              heap_size: '20g'
          network:
            name: "dsp_re7"

```

## Source Code

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
      # console.log @contexts('ryba/esdocker')[0]?.config.host is @config.host
      for es_name,es of es_docker.clusters 
        delete es_docker.clusters[es_name] unless es.only
      # console.log es_docker.clusters
      for es_name,es of es_docker.clusters
        es.normalized_name="#{es_name.replace(/_/g,"")}"
        #Docker:
        es.es_version ?= "2.3.3"
        es.docker_es_image = "dc-registry-bigdata.noe.edf.fr/elasticsearch:#{es.es_version}b"
        es.docker_kibana_image ?= "kibana:4.5"
        es.docker_logstash_image ?= "logstash"
        #Cluster
        es.number_of_containers ?= @contexts('ryba/docker-es').length
        es.number_of_shards ?= es.number_of_containers
        es.number_of_replicas ?= 1
        es.data_path ?= ["/data/1","/data/2","/data/3","/data/4","/data/5","/data/6","/data/7","/data/8"]
        es.logs_path ?= "/var/hadoop_log/docker/es"
        es.plugins_path ?= "/etc/elasticsearch/plugins"
        es.scripts_path ?= "/etc/elasticsearch/plugins"
        es.plugins ?= ["royrusso/elasticsearch-HQ","delete-by-query","mobz/elasticsearch-head","karmi/elasticsearch-paramedic/2.0"]
        es.volumes ?= []
        es.downloaded_urls = {}
        es.default_mem = '2g'
        # cpu quota 100%
        es.default_cpu_quota = 100000
        es.environment = "affinity:container!=*#{es.normalized_name}*"
        throw Error 'Required property "ports"' unless es.ports?
        if es.ports instanceof Array
          port_mapping = port.split(":").length > 1 for port in es.ports
          throw Error 'property "ports" must be an array of ports mapping ["9200:port1","9300:port2"]' unless port_mapping is true
        else
          throw Error 'property "ports" must be an array of ports mapping ["9200:port1","9300:port2"]'
        throw Error 'Required property "nodes"' unless es.nodes?
        throw Error 'Required property "network" and network.external' unless es.network?
        if es.kibana?
          throw Error 'Required property "kibana.port"' unless es.kibana.port?
        #TODO create overlay network if the network does not exist
        #For now We assume that the network is already created by docker network create
        es.network.external = true
        if es.logstash?
          throw Error 'Required property "logstash.port"' unless es.logstash.port?
          throw Error 'Required property "logstash.index"' unless es.logstash.index?
          throw Error 'Required property "logstash.doc_type"' unless es.logstash.doc_type?
          es.logstash.tag ?= 'TAG1'
          es.logstash.event_type ?= 'app_logs'
        es.total_nodes = 0
        es.master_nodes = 0
        es.data_nodes = 0
        es.master_data_nodes = 0
        for type,node of es.nodes
          throw Error 'Please specify number property for each node type under nodes property' unless node.number?
          node.mem_limit ?= es.default_mem
          heap_size =  if node.mem_limit is '1g' then '512mb' else Math.floor(parseInt(node.mem_limit.replace(/(g|mb)/i,'')) / 2 )
          node.heap_size ?= if node.mem_limit.indexOf('g') > -1 then heap_size+'g' else heap_size+'mb'
          node.cpu_quota ?= es.default_cpu_quota
          switch type
            when "master" then es.master_nodes = node.number
            when "data" then es.data_nodes =  node.number
            when "master_data" then es.master_data_nodes = node.number
        es.total_nodes = es.master_nodes + es.data_nodes + es.master_data_nodes
        #ES Config file
        es.config = {}
        es.config["bootstrap.mlockall"] = true
        es.config["network.host"] = "0.0.0.0"
        es.config["cluster.name"] = "#{es_name}"
        es.config["cluster.number_of_shards"] = es.number_of_shards
        es.config["cluster.number_of_replicas"] = es.number_of_replicas
        es.config["path.data"] = "#{es.data_path}"
        es.config["path.logs"] = "/var/log/elasticsearch"
        # reload scirpts every 12h
        es.config["resource.reload.interval"] = "43200s" 
        es.config["discovery.zen.minimum_master_nodes"] = Math.floor(es.total_nodes / 2) + 1
        es.config["gateway.expected_nodes"] = es.total_nodes
        es.config["gateway.recover_after_nodes"] = es.total_nodes - 1
        if es.graphite?
          throw Error 'Required property "graphite.host"' unless docker_es.graphite.host?
          throw Error 'Required property "graphite.port"' unless docker_es.graphite.port?
          es.config["metrics.graphite.host"] = docker_es.graphite.host
          es.config["metrics.graphite.port"] = docker_es.graphite.port
          es.config["metrics.graphite.every"] = docker_es.graphite.every ?= "10s"
          es.config["metrics.graphite.prefix"] = "es.#{es_name}.${HOSTNAME}"
        if "elasticsearch-repository-hdfs" in es.plugins
          es.config["security.manager.enabled"] = false
          es.config["repositories.hdfs.uri"] = "hdfs://torval:8020/"
          es.config["repositories.hdfs.path"] = "/backup/es"
          es.config["repositories.hdfs.conf_location"] = "/hadoop-config/core-site.xml,/hadoop-config/hdfs-site.xml"
          es.config["repositories.hdfs.user_keytab"] = "/hadoop-config/keytabs/dsp_app_adm.keytab"
          es.config["repositories.hdfs.user_principal"] = "dsp_app_adm@HADOOP.EDF.FR"
          es.volumes = [
            "/etc/krb5.conf:/etc/krb5.conf",
            "/etc/hadoop/conf/core-site.xml:/hadoop-config/core-site.xml",
            "/etc/hadoop/conf/hdfs-site.xml:/hadoop-config/hdfs-site.xml",
            "/etc/elasticsearch/keytabs:/hadoop-config/keytabs"
          ].concat es.volumes
        # es plugins urls
        es.plugins_urls = {}
        official_plugins = [
          "analysis-icu",
          "analysis-kuromoji",
          "analysis-phonetic",
          "analysis-smartcn",
          "analysis-stempel",
          "cloud-aws",
          "cloud-azure",
          "cloud-gce",
          "delete-by-query",
          "discovery-multicast",
          "lang-javascript",
          "lang-python",
          "mapper-attachments",
          "mapper-murmur3",
          "mapper-size"
        ]
        for name in es.plugins
          elements = name.split("/")
          [user,repo,version] = if elements.length == 1
            # plugin form: pluginName
            [null,elements[0],null]
          else if elements.length == 2
            #plugin form: userName/pluginName
            [elements[0],elements[1],null]
          else if elements.length == 3
            #plugin form: userName/pluginName/version
            [elements[0],elements[1],elements[2]]
          es.plugins_urls["#{repo}"] = []
          console.log "user: #{user} repo: #{repo} version: #{version}"
          if version is null && user is null && repo != null
            throw Error " #{repo} is not an official plugin so you should install it using elasticsearch/#{repo}/latest naming form." unless repo in official_plugins
            version = es.es_version
          if version != null
            if user is null
              es.plugins_urls["#{repo}"].push "https://download.elastic.co/elasticsearch/release/org/elasticsearch/plugin/#{repo}/#{version}/#{repo}-#{version}.zip"
            else
              es.plugins_urls["#{repo}"].push "https://download.elastic.co/#{user}/#{repo}/#{repo}-#{version}.zip"
              es.plugins_urls["#{repo}"].push "https://search.maven.org/remotecontent?filepath=#{user.replace('.','/')}/#{repo}/#{version}/#{repo}-#{version}.zip"
              es.plugins_urls["#{repo}"].push "https://oss.sonatype.org/service/local/repositories/releases/content/#{user.replace('.','/')}/#{repo}/#{version}/#{repo}-#{version}.zip"
              es.plugins_urls["#{repo}"].push "https://github.com/#{user}/#{repo}/archive/#{version}.zip"
          if user != null
            es.plugins_urls["#{repo}"].push "https://github.com/#{user}/#{repo}/archive/master.zip"
