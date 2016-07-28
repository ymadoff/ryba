## Configure Solr Cloud cluster on docker 

This module configures the servers to be able to run different solrCloud cluster in 
docker containers. The configuration is made in two steps:
- The first is to create host level configuration as we would do without docker
The host level configuration will be shared by the different containers running 
on the same host.
- The second step consists to configure each SolrCloud cluster  on the container level
by looping through each on of it and configuring the different properties.
These properties are unique to each container, depending on the cluster/host it 
belongs to.
For now we supports only (at the cluster level) only one container by host.


Solr accepts differents sources:
 - HDP to use HDP lucidworks repos

```cson
ryba:
  solr: 
    source: 'HDP'
    jre_home: '/usr/java/jdk1.8.0_91/jre'
    env:
      'SOLR_JAVA_HOME': '/usr/java/jdk1.8.0_91'
```
 - apache community edition to use the official release:   
 in this case you can choose the version

```cson
ryba:
  solr: 
    jre_home: '/usr/java/jdk1.8.0_91/jre'
    env:
      'SOLR_JAVA_HOME': '/usr/java/jdk1.8.0_91'
    version: '6.0.0'
    source: 'http://mirrors.ircam.fr/pub/apache/lucene/solr/6.0.0/solr-6.0.0.tgz'
```

    module.exports = handler: ->
      {java, ryba} = @config
      {solr, realm} = ryba ?= {}
      solr.user ?= {}
      solr.user = name: solr.user if typeof solr.user is 'string'
      solr.user.name ?= 'solr'
      solr.user.home ?= "/var/#{solr.user.name}/data"
      solr.user.system ?= true
      solr.user.comment ?= 'Solr User'
      solr.user.groups ?= 'hadoop'
      # Group
      solr.group ?= {}
      solr.group = name: solr.group if typeof solr.group is 'string'
      solr.group.name ?= 'solr'
      solr.group.system ?= true
      solr.user.gid ?= solr.group.name
      solr.cloud_docker ?= {}
      solr.cloud_docker.version ?= '5.5.0'
      solr.cloud_docker.source ?= "http://apache.mirrors.ovh.net/ftp.apache.org/dist/lucene/solr/#{solr.cloud_docker.version}/solr-#{solr.cloud_docker.version}.tgz"
      solr.cloud_docker.root_dir ?= '/usr'
      solr.cloud_docker.install_dir ?= "#{solr.cloud_docker.root_dir}/solr-cloud/#{solr.cloud_docker.version}"
      solr.cloud_docker.latest_dir ?= "#{solr.cloud_docker.root_dir}/solr-cloud/current"
      solr.cloud_docker.latest_dir = '/opt/lucidworks-hdpsearch/solr' if solr.cloud_docker.source is 'HDP'
      solr.cloud_docker.pid_dir ?= '/var/run/solr'
      solr.cloud_docker.log_dir ?= '/var/log/solr'
      solr.cloud_docker.conf_dir ?= '/etc/solr-cloud-docker/conf'
      solr.cloud_docker.build ?= {}
      solr.cloud_docker.build.dir ?= "#{@config.mecano.cache_dir}/solr"
      solr.cloud_docker.build.image ?= "ryba/solr"
      solr.cloud_docker.build.version ?= "5.5"
      solr.cloud_docker.build.tar ?= "solr_image.tar"

## Core Conf

      # Layout
      solr.cloud_docker.env ?= {}
      zk_hosts = @contexts 'ryba/zookeeper/server', require("#{__dirname}/../../zookeeper/server/configure").handler
      solr.cloud_docker.zk_connect = zk_hosts.map( (ctx) -> "#{ctx.config.host}:#{ctx.config.ryba.zookeeper.port}").join ','
      solr.cloud_docker.zkhosts = "#{solr.cloud_docker.zk_connect}/solr"
      solr.cloud_docker.zk_node = "/solr"
      solr.cloud_docker.dir_factory ?= "${solr.directoryFactory:solr.NRTCachingDirectoryFactory}"
      solr.cloud_docker.lock_type = 'native'

## Fix Conf
Before 6.0 version, solr.xml'<solrCloud> section has a mistake:
The property `zkCredentialsProvider` was named `zkCredientialsProvider`

      solr.cloud_docker.conf_source = if (solr.cloud_docker.version.split('.')[0] < 6) or (solr.cloud_docker.source is 'HDP')
      then "#{__dirname}/../resources/cloud/solr_5.xml.j2"
      else "#{__dirname}/../resources/cloud/solr_6.xml.j2"      
      
## Security

      solr.cloud_docker.security ?= {}
      solr.cloud_docker.security["authentication"] ?= {}
      solr.cloud_docker.security["authentication"]['class'] ?= if  @config.ryba.security is 'kerberos'
      then 'org.apache.solr.security.KerberosPlugin'
      else 'solr.BasicAuthPlugin'
      if @config.ryba.security is 'kerberos'
        # Kerberos
        solr.cloud_docker.admin_principal ?= "#{solr.user.name}@#{realm}"
        solr.cloud_docker.admin_password ?= 'solr123'
        solr.cloud_docker.principal ?= "#{solr.user.name}/#{@config.host}@#{realm}"
        solr.cloud_docker.keytab ?= '/etc/security/keytabs/solr.service.keytab'
        solr.cloud_docker.spnego ?= {}
        solr.cloud_docker.spnego.principal ?= "HTTP/#{@config.host}@#{@config.ryba.realm}"
        solr.cloud_docker.spnego.keytab ?= '/etc/security/keytabs/spnego.service.keytab'
        solr.cloud_docker.auth_opts ?= {}
        solr.cloud_docker.auth_opts['solr.kerberos.cookie.domain'] ?= "#{@config.host}"
        solr.cloud_docker.auth_opts['java.security.auth.login.config'] ?= "#{solr.cloud_docker.conf_dir}/solr-server.jaas"
        solr.cloud_docker.auth_opts['solr.kerberos.principal'] ?= solr.cloud_docker.spnego.principal
        solr.cloud_docker.auth_opts['solr.kerberos.keytab'] ?= solr.cloud_docker.spnego.keytab
        solr.cloud_docker.auth_opts['solr.kerberos.name.rules'] ?= "RULE:[1:\\$1]RULE:[2:\\$1]"
        # Authentication

## SSL

      solr.cloud ?= {}
      solr.cloud.port ?= 8893
      solr.cloud_docker.ssl ?= {}
      solr.cloud_docker.ssl.enabled ?= true
      solr.cloud_docker.ssl_truststore_path ?= "#{solr.cloud_docker.conf_dir}/truststore"
      solr.cloud_docker.ssl_truststore_pwd ?= 'solr123'
      solr.cloud_docker.ssl_keystore_path ?= "#{solr.cloud_docker.conf_dir}/keystore"
      solr.cloud_docker.ssl_keystore_pwd ?= 'solr123'

### Environment

      solr.cloud_docker.env['SOLR_JAVA_HOME'] ?= java.java_home
      solr.cloud_docker.env['SOLR_HOST'] ?= @config.host
      solr.cloud_docker.env['SOLR_PID_DIR'] ?= solr.cloud_docker.pid_dir
      solr.cloud_docker.env['SOLR_HEAP'] ?= "512m"
      solr.cloud_docker.env['ENABLE_REMOTE_JMX_OPTS'] ?= 'false'
      if solr.cloud_docker.ssl.enabled
        solr.cloud_docker.env['SOLR_SSL_KEY_STORE'] ?= solr.cloud_docker.ssl_keystore_path
        solr.cloud_docker.env['SOLR_SSL_KEY_STORE_PASSWORD'] ?= solr.cloud_docker.ssl_keystore_pwd
        solr.cloud_docker.env['SOLR_SSL_TRUST_STORE'] ?= solr.cloud_docker.ssl_truststore_path
        solr.cloud_docker.env['SOLR_SSL_TRUST_STORE_PASSWORD'] ?= solr.cloud_docker.ssl_truststore_pwd
        solr.cloud_docker.env['SOLR_SSL_NEED_CLIENT_AUTH'] ?= 'false'#require client authentication  by using cert

### Configure SolrCloud Clusters
This module enable adminstrator to instantiate several solrcloud clusters.
The clusters are described in `solr.cloud_docker.clusters` property.
Example of config for a solr cluster.
The Settings for each solr node in a solrcloud cluster will be the same.

Note: We use the host network when running the container, because of hostname mapping 
when spnego principal is created.

Note-2: Can not start more than one container on the same host becausewe are using
network_mode: host (port collision).

```cson
  "ryba_snapshot":
    containers: 2
    master: 'master1.ryba'
    hosts: ['master1.ryba', 'master2.ryba', 'master3.ryba']
    env:
      'SOLR_JAVA_HOME': '/user/java/jre'
    security: 
      'authorization': 
        'class': 'solr.RuleBasedAuthorizationPlugin'
    data_dir: '/var/my_data_dir'
    log_dir: '/var/log/solr/ryba_snapshot'
    pid_dir: '/var/run/solr/solr.pid'
    heap_size: '1024m'
    port: 10000
    zk_node: 'my_cluster'
    only: true    
```

      for name,config of solr.cloud_docker.clusters
        config.hosts ?= @contexts('ryba/solr/cloud_docker').map((c)->c.config.host)
        throw Error "Malformed Master for cluster: #{name}" unless config.hosts.indexOf config['master'] > -1
        throw Error "Missing port for cluster: #{name}"  unless config.port?
        throw Error "Name should not contain -" if /-+/.test name
        # Cluster config 
        # Docker-compose config
        config.mem_limit ?= '1g'
        # config.cpu_shares ?= 5
        # config.cpu_quota ?= 50 * 1000
        config.heap_size ?= '1024m'
        config.data_dir ?= "#{solr.user.home}/#{name}"
        config.log_dir ?= "/var/log/solr/#{name}"
        config.pid_dir ?= "/var/run/solr/#{name}"
        config.zk_node ?= "solr_#{name}"
        config.service_def ?= {}
        config['env'] ?= {}
        volumes = [
            "#{solr.cloud_docker.conf_dir}/clusters/#{name}/docker_entrypoint.sh:/docker_entrypoint.sh"
            "#{solr.cloud_docker.conf_dir}/keystore:#{solr.cloud_docker.conf_dir}/keystore"
            "#{solr.cloud_docker.conf_dir}/truststore:#{solr.cloud_docker.conf_dir}/truststore"
            "#{solr.cloud_docker.conf_dir}/solr-server.jaas:#{solr.cloud_docker.conf_dir}/solr-server.jaas"
            "#{solr.cloud_docker.conf_dir}/clusters/#{name}/solr.in.sh:#{solr.cloud_docker.conf_dir}/solr.in.sh"
            "#{solr.cloud_docker.conf_dir}/solr.xml:#{solr.cloud_docker.conf_dir}/solr.xml"
            "#{config.data_dir}:/var/solr/data"
            "#{config.log_dir}:#{solr.cloud_docker.latest_dir}/server/logs"
            "/etc/security/keytabs:/etc/security/keytabs"
            "/etc/krb5.conf:/etc/krb5.conf"
          ]
        config.master_configured = false
        for node in [1..config.containers]
          command = "/docker_entrypoint.sh --zk_node #{config.zk_node} " # --port #{config.port}"
          environment = []
          # `affinity:container` enables docker to start a new container on a host 
          # where no other container belonging to the cluster is already running.
          environment.push "affinity:container!=*#{name.split('_').join('')}_node*"
          # We need to set master property to now which server will launch bootstrap
          # command and get it's node name (solr node inside a container for a cluster).
          if config['master'] is @config.host and not config.master_configured
            # --bootstrap args in commands enable master to create the zookeeper 
            # node for the current cluster. Check docker_entrypoint.sh file for more infos.
            command += " --bootstrap"
            config.master_node = node
            config.master_configured = true
          #docker-compose.yml container specific properties
          config.service_def["node_#{node}"]=
            'image' : "#{solr.cloud_docker.build.image}:#{solr.cloud_docker.build.version}"
            'restart': "always"
            'command': command
            'volumes': volumes
            'ports': solr.port
            'network_mode': 'host'
            'mem_limit': config.mem_limit
            'cpu_shares': config.cpu_shares
            'cpu_quota': config.cpu_quota
          config.service_def["node_#{node}"]['environment'] = environment if  environment.length > 0
        # solr.in.sh node specific properties
        # Custom Host config (a container for a host)
        config_hosts = config.config_hosts = {}
        for host in config.hosts
          if host is @config.host
            config_host = config_hosts["#{host}"] ?= {}
            # Configure host environment config
            config_host['env'] ?= {}
            config_host['env']['SOLR_HOME'] ?= "#{solr.user.home}"
            config_host['env']['SOLR_PORT'] ?= "#{config.port}"
            config_host['env']['SOLR_AUTHENTICATION_OPTS'] ?= "-Djetty.port=#{config.port}" #backward compatibility
            config_host['env']['ZK_HOST'] ?= "#{solr.cloud_docker.zk_connect}/#{config.zk_node}"
            for prop in [
              'SOLR_JAVA_HOME'
              'ENABLE_REMOTE_JMX_OPTS'
              'SOLR_SSL_KEY_STORE'
              'SOLR_SSL_KEY_STORE_PASSWORD'
              'SOLR_SSL_TRUST_STORE'
              'SOLR_SSL_TRUST_STORE_PASSWORD'
              'SOLR_SSL_NEED_CLIENT_AUTH'
              'SOLR_HOST'
              'SOLR_PID_DIR'
            ] then config_host['env'][prop] ?= config_host['env'][prop] ?= config['env'][prop] ?= solr.cloud_docker['env'][prop] 
            # Authentication & Authorization
            config_host.security = config.security ?= {}
            config_host.security["authentication"] ?= {}
            config_host.security["authentication"]['class'] ?= if  @config.ryba.security is 'kerberos'
            then 'org.apache.solr.security.KerberosPlugin'
            else 'solr.BasicAuthPlugin'
            config_host.security['authentication']['blockUnknown'] ?= true 
            # ACLs
            config_host.security["authorization"] ?= {}
            config_host.security["authorization"]['class'] ?= 'solr.RuleBasedAuthorizationPlugin'
            config_host.security["authorization"]['permissions'] ?= []
            # config_host.security["authorization"]['permissions'].push name: 'security-edit' , role: 'admin' unless config_host.security["authorization"]['permissions'].indexOf({name: 'security-edit' , role: 'admin'}) > -1 #define new role 
            # config_host.security["authorization"]['permissions'].push name: 'read' , role: 'reader' unless config_host.security["authorization"]['permissions'].indexOf({name: 'read' , role: 'reader' }) > -1  #define new role
            config_host.security["authorization"]['permissions'].push name: 'all' , role: 'manager' unless config_host.security["authorization"]['permissions'].indexOf({name: 'all' , role: 'manager' }) > -1  #define new role
            config_host.security["authorization"]['user-role'] ?= {}
            if config_host.security["authentication"]['class'] is 'org.apache.solr.security.KerberosPlugin'
              config_host['env']['SOLR_AUTHENTICATION_CLIENT_CONFIGURER'] ?= 'org.apache.solr.client.solrj.impl.Krb5HttpClientConfigurer' 
              config_host.security["authorization"]['user-role']["#{solr.cloud_docker.admin_principal}"] ?= 'manager'
              for host in config.hosts
                config_host.security["authorization"]['user-role']["#{solr.user.name}/#{host}@#{@config.ryba.realm}"] ?= 'manager'
                config_host.security["authorization"]['user-role']["HTTP/#{host}@#{@config.ryba.realm}"] ?= 'manager'
            else
              # Create solr:SolrRocks default user/pwd by default
              config_host.security['authentication']['credentials'] ?= {} 
              config_host.security['authentication']['credentials']['solr'] ='IV0EHq1OnNrj6gvRCwvFwTrZ1+z1oBbnQdiVC3otuq0= Ndd7LKvVBAaZIF0QAVi1ekCfAJXr1GGfLtRUXhgrF8c='
              # Gives it admin role
              config_host.security["authorization"]['user-role']['solr'] ?= 'admin'
            # Env opts
            config_host.auth_opts ?= {}
            config_host.auth_opts['solr.kerberos.cookie.domain'] ?= "#{@config.host}"
            config_host.auth_opts['java.security.auth.login.config'] ?= "#{solr.cloud_docker.conf_dir}/solr-server.jaas"
            config_host.auth_opts['solr.kerberos.principal'] ?= solr.cloud_docker.spnego.principal
            config_host.auth_opts['solr.kerberos.keytab'] ?= solr.cloud_docker.spnego.keytab
            config_host.auth_opts['solr.kerberos.name.rules'] ?= "RULE:[1:\\$1]RULE:[2:\\$1]"
