
# Hadoop Core Configuration

*   `hdfs.user` (object|string)
    The Unix HDFS login name or a user object (see Mecano User documentation).
*   `yarn.user` (object|string)
    The Unix YARN login name or a user object (see Mecano User documentation).
*   `mapred.user` (object|string)
    The Unix MapReduce login name or a user object (see Mecano User documentation).
*   `user` (object|string)
    The Unix Test user name or a user object (see Mecano User documentation).
*   `hadoop_group` (object|string)
    The Unix Hadoop group name or a group object (see Mecano Group documentation).
*   `hdfs.group` (object|string)
    The Unix HDFS group name or a group object (see Mecano Group documentation).
*   `yarn.group` (object|string)
    The Unix YARN group name or a group object (see Mecano Group documentation).
*   `mapred.group` (object|string)
    The Unix MapReduce group name or a group object (see Mecano Group documentation).
*   `group` (object|string)
    The Unix Test group name or a group object (see Mecano Group documentation).

Default configuration:

```json
{
  "ryba": {
    "user": {
      "name": "ryba", "system": true, "gid": "ryba",
      "comment": "ryba User", "home": "/home/ryba"
    },
    "group": {
      "name": "ryba", "system": true
    },
    "hdfs": {
      "user": {
        "name": "hdfs", "system": true, "gid": "hdfs",
        "comment": "HDFS User", "home": "/var/lib/hadoop-hdfs"
      },
      "group": {
        "name": "hdfs", "system": true
      }
    },
    "yarn: {
      "user": {
        "name": "yarn", "system": true, "gid": "yarn",
        "comment": "YARN User", "home": "/var/lib/hadoop-yarn"
      },
      "group": {
        "name": "yarn", "system": true
      }
    },
    "mapred": {
      "user": {
        "name": "mapred", "system": true, "gid": "mapred",
        "comment": "MapReduce User", "home": "/var/lib/hadoop-mapreduce"
      },
      "group": {
        "name": "mapred", "system": true
      }
    },
    "hadoop_group": {
      "name": "hadoop", "system": true
    }
  }
}
```

    module.exports = handler: ->
      {realm, ganglia, graphite} = @config.ryba
      ryba = @config.ryba ?= {}
      ryba.yarn ?= {}
      ryba.mapred ?= {}

## Configuration for users and groups

      # Group for hadoop
      ryba.hadoop_group = name: ryba.hadoop_group if typeof ryba.hadoop_group is 'string'
      ryba.hadoop_group ?= {}
      ryba.hadoop_group.name ?= 'hadoop'
      ryba.hadoop_group.system ?= true
      # Unix user hdfs
      ryba.hdfs.user ?= {}
      ryba.hdfs.user = name: ryba.hdfs.user if typeof ryba.hdfs.user is 'string'
      ryba.hdfs.user.name ?= 'hdfs'
      ryba.hdfs.user.system ?= true
      ryba.hdfs.user.groups ?= 'hadoop'
      ryba.hdfs.user.comment ?= 'Hadoop HDFS User'
      ryba.hdfs.user.home ?= '/var/lib/hadoop-hdfs'
      ryba.hdfs.user.limits ?= {}
      ryba.hdfs.user.limits.nofile ?= 64000
      ryba.hdfs.user.limits.nproc ?= true
      # Unix user for yarn
      ryba.yarn.user ?= {}
      ryba.yarn.user = name: ryba.yarn.user if typeof ryba.yarn.user is 'string'
      ryba.yarn.user.name ?= 'yarn'
      ryba.yarn.user.system ?= true
      ryba.yarn.user.groups ?= 'hadoop'
      ryba.yarn.user.comment ?= 'Hadoop YARN User'
      ryba.yarn.user.home ?= '/var/lib/hadoop-yarn'
      ryba.yarn.user.limits ?= {}
      ryba.yarn.user.limits.nofile ?= 64000
      ryba.yarn.user.limits.nproc ?= true
      # Unix user for mapred
      ryba.mapred.user ?= {}
      ryba.mapred.user = name: ryba.mapred.user if typeof ryba.mapred.user is 'string'
      ryba.mapred.user.name ?= 'mapred'
      ryba.mapred.user.system ?= true
      ryba.mapred.user.groups ?= 'hadoop'
      ryba.mapred.user.comment ?= 'Hadoop MapReduce User'
      ryba.mapred.user.home ?= '/var/lib/hadoop-mapreduce'
      ryba.mapred.user.limits ?= {}
      ryba.mapred.user.limits.nofile ?= 64000
      ryba.mapred.user.limits.nproc ?= true
      # Groups
      ryba.hdfs.group ?= {}
      ryba.hdfs.group = name: ryba.hdfs.group if typeof ryba.hdfs.group is 'string'
      ryba.hdfs.group.name ?= 'hdfs'
      ryba.hdfs.group.system ?= true
      ryba.hdfs.user.gid = ryba.hdfs.group.name
      ryba.yarn.group ?= {}
      ryba.yarn.group = name: ryba.yarn.group if typeof ryba.yarn.group is 'string'
      ryba.yarn.group.name ?= 'yarn'
      ryba.yarn.group.system ?= true
      ryba.yarn.user.gid = ryba.yarn.group.name
      ryba.mapred.group ?= {}
      ryba.mapred.group = name: ryba.mapred.group if typeof ryba.mapred.group is 'string'
      ryba.mapred.group.name ?= 'mapred'
      ryba.mapred.group.system ?= true
      ryba.mapred.user.gid = ryba.mapred.group.name
      ryba.group ?= {}
      ryba.group = name: ryba.group if typeof ryba.group is 'string'
      ryba.group.name ?= 'ryba'
      ryba.group.system ?= true
      # Layout
      ryba.hadoop_conf_dir ?= '/etc/hadoop/conf'
      ryba.hadoop_lib_home ?= '/usr/hdp/current/hadoop-client/lib' # refered by oozie-env.sh
      ryba.hdfs.log_dir ?= '/var/log/hadoop-hdfs'
      ryba.hdfs.pid_dir ?= '/var/run/hadoop-hdfs'
      ryba.hdfs.secure_dn_pid_dir ?= '/var/run/hadoop-hdfs' # /$HADOOP_SECURE_DN_USER
      ryba.hdfs.secure_dn_user ?= ryba.hdfs.user.name
      # HA Configuration
      ryba.nameservice ?= null
      # ryba.active_nn ?= false
      throw new Error "Invalid Service Name" unless ryba.nameservice
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
      # Configuration
      core_site = ryba.core_site ?= {}
      core_site['io.compression.codecs'] ?= "org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.SnappyCodec"
      if nn_ctxs.length is 1
        core_site['fs.defaultFS'] ?= "hdfs://#{nn_ctxs[0].config.host}:8020"
      else if nn_ctxs.length is 2
        core_site['fs.defaultFS'] ?= "hdfs://#{ryba.nameservice}:8020"
        ryba.active_nn_host ?= nn_ctxs[0].config.host
        # [active_nn_ctxs] = nn_ctxs.filter( (nn_ctx) => nn_ctx.config.host is ryba.active_nn_host )
        [standby_nn_ctxs] = nn_ctxs.filter( (nn_ctx) => nn_ctx.config.host isnt ryba.active_nn_host )
        ryba.standby_nn_host = standby_nn_ctxs.config.host
      else throw Error "Invalid number of NanodeNodes, got #{nn_ctxs.length}, expecting 2"
        
      # Set the authentication for the cluster. Valid values are: simple or kerberos
      core_site['hadoop.security.authentication'] ?= 'kerberos'
      # Enable authorization for different protocols.
      core_site['hadoop.security.authorization'] ?= 'true'
      # A comma-separated list of protection values for secured sasl
      # connections. Possible values are authentication, integrity and privacy.
      # authentication means authentication only and no integrity or privacy;
      # integrity implies authentication and integrity are enabled; and privacy
      # implies all of authentication, integrity and privacy are enabled.
      # hadoop.security.saslproperties.resolver.class can be used to override
      # the hadoop.rpc.protection for a connection at the server side.
      core_site['hadoop.rpc.protection'] ?= 'authentication'
      # Default group mapping
      core_site['hadoop.security.group.mapping'] ?= 'org.apache.hadoop.security.JniBasedUnixGroupsMappingWithFallback'
      # Core Jars
      core_jars = @config.ryba.core_jars ?= {}
      for k, v of core_jars
        throw Error 'Invalid core_jars source' unless v.source
        v.match ?= "#{k}-*.jar"
        v.filename = path.basename v.source
      # Get ZooKeeper Quorum
      zoo_ctxs = @contexts 'ryba/zookeeper/server', require('../../zookeeper/server/configure').handler
      zookeeper_quorum = for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
      core_site['ha.zookeeper.quorum'] ?= zookeeper_quorum
      # Topology
      # http://ofirm.wordpress.com/2014/01/09/exploring-the-hadoop-network-topology/
      core_site['net.topology.script.file.name'] ?= "#{ryba.hadoop_conf_dir}/rack_topology.sh"

Kerberos user for hdfs

      ryba.hdfs.krb5_user ?= {}
      ryba.hdfs.krb5_user.principal ?= "#{ryba.hdfs.user.name}@#{realm}"
      ryba.hdfs.krb5_user.password ?= 'password'

Configuration for HTTP

      core_site['hadoop.http.filter.initializers'] ?= 'org.apache.hadoop.security.AuthenticationFilterInitializer'
      core_site['hadoop.http.authentication.type'] ?= 'kerberos'
      core_site['hadoop.http.authentication.token.validity'] ?= '36000'
      core_site['hadoop.http.authentication.signature.secret.file'] ?= '/etc/hadoop/hadoop-http-auth-signature-secret'
      core_site['hadoop.http.authentication.simple.anonymous.allowed'] ?= 'false'
      core_site['hadoop.http.authentication.kerberos.principal'] ?= "HTTP/_HOST@#{ryba.realm}"
      core_site['hadoop.http.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab'
      # Cluster domain
      unless core_site['hadoop.http.authentication.cookie.domain']
        domains = @contexts('ryba/hadoop/core').map( (ctx) -> ctx.config.host.split('.').slice(1).join('.') ).filter( (el, pos, self) -> self.indexOf(el) is pos )
        throw Error "Multiple domains, set 'hadoop.http.authentication.cookie.domain' manually" if domains.length isnt 1
        core_site['hadoop.http.authentication.cookie.domain'] = domains[0]

Configuration for auth\_to\_local

The local name will be formulated from exp.
The format for exp is [n:string](regexp)s/pattern/replacement/g.
The integer n indicates how many components the target principal should have. 
If this matches, then a string will be formed from string, substituting the realm 
of the principal for $0 and the n‘th component of the principal for $n. 
If this string matches regexp, then the s//[g] substitution command will be run 
over the string. The optional g will cause the substitution to be global over 
the string, instead of replacing only the first match in the string.
The rule apply with priority order, so we write rules from the most specific to
the most general:
There is 4 identified cases:

*   The principal is a 'sub-service' principal from our internal realm. It replaces with the corresponding service name
*   The principal is from our internal realm. We apply DEFAULT rule (It takes the first component of the principal as a
    username. Only apply on the internal realm)
*   The principal is NOT from our realm, and would be mapped to an admin user like hdfs. It maps it to 'nobody'
*   The principal is NOT from our internal realm, and do NOT match any admin account.
    It takes the first component of the principal as username.

Notice that the third rule will disallow admin account on multiple clusters.
the property must be overriden in a config file to permit it. 

      esc_realm = quote realm
      core_site['hadoop.security.auth_to_local'] ?= """

            RULE:[2:$1@$0]([rn]m@#{esc_realm})s/.*/yarn/
            RULE:[2:$1@$0](jhs@#{esc_realm})s/.*/mapred/
            RULE:[2:$1@$0]([nd]n@#{esc_realm})s/.*/hdfs/
            RULE:[2:$1@$0](hm@#{esc_realm})s/.*/hbase/
            RULE:[2:$1@$0](rs@#{esc_realm})s/.*/hbase/
            RULE:[2:$1@$0](opentsdb@#{esc_realm})s/.*/hbase/
            DEFAULT
            RULE:[1:$1](yarn|mapred|hdfs|hive|hbase|oozie)s/.*/nobody/
            RULE:[2:$1](yarn|mapred|hdfs|hive|hbase|oozie)s/.*/nobody/
            RULE:[1:$1]
            RULE:[2:$1]

      """

Configuration for proxy users

      core_site['hadoop.proxyuser.HTTP.hosts'] ?= '*'
      core_site['hadoop.proxyuser.HTTP.groups'] ?= '*'

Configuration for environment

      ryba.hadoop_opts ?= '-Djava.net.preferIPv4Stack=true'
      ryba.hadoop_classpath ?= ''
      ryba.hadoop_heap ?= '1024'
      ryba.hadoop_namenode_init_heap ?= '-Xms1024m'
      # if Array.isArray ryba.hadoop_opts
      #   ryba.hadoop_opts = ryba.hadoop_opts.join ' '
      # if typeof ryba.hadoop_opts is 'object'
      #   hadoop_opts = ''
      #   for k, v of ryba.hadoop_opts
      #     hadoop_opts += "-D#{k}=#{v} "
      #   ryba.hadoop_opts = hadoop_opts
      # hadoop_opts = "export HADOOP_OPTS=\""
      # for k, v of ryba.hadoop_opts
      #   hadoop_opts += "-D#{k}=#{v} "
      # hadoop_opts += "${HADOOP_OPTS}\""
      # ryba.hadoop_opts = hadoop_opts
      ryba.hadoop_client_opts ?= '-Xmx2048m'
      # hadoop_client_opts = ryba.hadoop_client_opts ?= '-Xmx2048m'
      # ryba.hadoop_client_opts = "export HADOOP_CLIENT_OPTS=\"#{hadoop_client_opts} $HADOOP_CLIENT_OPTS\""
      # Options for "hadoop-policy.xml"
      # Note, according to the doc, it apply to the NameNode and JobTracker
      # where JobTracker shall be understood as RerouceManager
      ryba.hadoop_policy ?= {}

## Configuration for metrics

Configuration of Hadoop metrics system. 

The File sink is activated by default. The Ganglia and Graphite sinks are
automatically activated if the "ryba/ganglia/collector" and
"ryba/graphite/collector" are respectively registered on one of the nodes of the
cluster. You can disable any of those sinks by setting its class to false, here
how:

```json
{ "ryba": { "metrics": 
  "*.sink.file.class": false, 
  "*.sink.ganglia.class": false, 
  "*.sink.graphite.class": false
 } }
```

Metric prefix can be defined globally with the usage of glob expression or per
context. Here's an exemple:

```json
{ "ryba": { "hadoop_metrics": 
  "*.sink.*.metrics_prefix": "default", 
  "*.sink.file.metrics_prefix": "file_prefix", 
  "namenode.sink.ganglia.metrics_prefix": "master_prefix", 
  "resourcemanager.sink.ganglia.metrics_prefix": "master_prefix"
 } }
```

Syntax is "[prefix].[source|sink].[instance].[options]".  According to the
source code, the list of supported prefixes is: "namenode", "resourcemanager",
"datanode", "nodemanager", "maptask", "reducetask", "journalnode",
"historyserver", "nimbus", "supervisor".

      sinks = @config.metrics_sinks ?= {}
      # File sink
      sinks.file ?= {}
      sinks.file.class ?= 'org.apache.hadoop.metrics2.sink.FileSink'
      sinks.file.filename ?= 'metrics.out'
      # Ganglia Sink
      sinks.ganglia ?= {}
      sinks.ganglia.class ?= 'org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31'
      sinks.ganglia.period ?= '10'
      sinks.ganglia.supportparse ?= 'true' # Setting to "true" helps in reducing bandwith (see "Practical Hadoop Security")
      sinks.ganglia.slope ?= 'jvm.metrics.gcCount=zero,jvm.metrics.memHeapUsedM=both'
      sinks.ganglia.dmax ?= 'jvm.metrics.threadsBlocked=70,jvm.metrics.memHeapUsedM=40' # How long a particular value will be retained
      # Graphite Sink
      sinks.graphite ?= {}
      sinks.graphite.class ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'
      sinks.graphite.period ?= '10'
      # Hadoop metrics
      hadoop_metrics = @config.ryba.hadoop_metrics ?= {}
      hadoop_metrics.sinks ?= {}
      hadoop_metrics.sinks.file ?= true
      hadoop_metrics.sinks.ganglia ?= false
      hadoop_metrics.sinks.graphite ?= false
      hadoop_metrics.config ?= {}
      # default sampling period, in seconds
      hadoop_metrics.config['*.period'] ?= '60'
      # File sink
      if hadoop_metrics.sinks.file
        hadoop_metrics.config["*.sink.file.#{k}"] ?= v for k, v of sinks.file
        hadoop_metrics.config['namenode.sink.file.filename'] ?= 'namenode-metrics.out'
        hadoop_metrics.config['datanode.sink.file.filename'] ?= 'datanode-metrics.out'
        hadoop_metrics.config['resourcemanager.sink.file.filename'] ?= 'resourcemanager-metrics.out'
        hadoop_metrics.config['nodemanager.sink.file.filename'] ?= 'nodemanager-metrics.out'
        hadoop_metrics.config['mrappmaster.sink.file.filename'] ?= 'mrappmaster-metrics.out'
        hadoop_metrics.config['jobhistoryserver.sink.file.filename'] ?= 'jobhistoryserver-metrics.out'
      # Ganglia sink, accepted properties are "servers" and "supportsparse"
      if hadoop_metrics.sinks.ganglia
        [ganglia_ctx] =  @contexts 'ryba/ganglia/collector'
        hadoop_metrics.config["*.sink.ganglia.#{k}"] ?= v for k, v of sinks.ganglia
        if @has_module 'ryba/hadoop/hdfs_nn'
          hadoop_metrics.config['namenode.sink.ganglia.class'] ?= sinks.ganglia.class
          hadoop_metrics.config['namenode.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.nn_port}"
        if @has_module 'ryba/hadoop/yarn_rm'
          hadoop_metrics.config['resourcemanager.sink.ganglia.class'] ?= sinks.ganglia.class
          hadoop_metrics.config['resourcemanager.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.rm_port}"
        if @has_module 'ryba/hadoop/hdfs_dn'
          hadoop_metrics.config['datanode.sink.ganglia.class'] ?= sinks.ganglia.class
          hadoop_metrics.config['datanode.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.nn_port}"
        if @has_module 'ryba/hadoop/yarn_nm'
          hadoop_metrics.config['nodemanager.sink.ganglia.class'] ?= sinks.ganglia.class
          hadoop_metrics.config['nodemanager.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.nn_port}"
          hadoop_metrics.config['maptask.sink.ganglia.class'] ?= sinks.ganglia.class
          hadoop_metrics.config['maptask.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.nn_port}"
          hadoop_metrics.config['reducetask.sink.ganglia.class'] ?= sinks.ganglia.class
          hadoop_metrics.config['reducetask.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.nn_port}"
        # if @has_module 'ryba/hadoop/hdfs_jn'
        #   hadoop_metrics['journalnode.sink.ganglia.servers']
        # if @has_module 'ryba/hadoop/mapred_jhs'
        #   hadoop_metrics['historyserver.sink.ganglia.servers']
        # if @has_module 'ryba/storm/nimbus'
        #   hadoop_metrics['nimbus.sink.ganglia.servers']
        # if @has_module 'ryba/storm/supervisor'
        #   hadoop_metrics['supervisor.sink.ganglia.servers']
      # Graphite sink, accepted properties are "server_host", "server_port" and "metrics_prefix"
      if hadoop_metrics.sinks.graphite
        throw Error 'Unvalid metrics sink, please provide @config.metrics_sinks.graphite.server_host and server_port' unless sinks.graphite.server_host? and sinks.graphite.server_port?
        hadoop_metrics.config["*.sink.graphite.#{k}"] ?= v for k, v of sinks.graphite
        for mod, modlist of {
          'ryba/hadoop/hdfs_nn': ['namenode']
          'ryba/hadoop/yarn_rm': ['resourcemanager'] 
          'ryba/hadoop/hdfs_dn': ['datanode']
          'ryba/hadoop/yarn_nm': ['nodemanager', 'maptask', 'reducetask']
          'ryba/hadoop/hdfs_jn': ['journalnode']
          'ryba/hadoop/mapred_jhs': ['historyserver']
        }
        then if @has_module mod
        then for k in modlist
          hadoop_metrics.config["#{k}.sink.graphite.class"] ?= sinks.graphite.class

# SSL

Hortonworks mentions 2 strategies to [configure SSL][hdp_ssl], the first one
involves Self-Signed Certificate while the second one use a Certificate
Authority.

For now, only the second approach has been tested and is supported. For this, 
you are responsible for creating your own Private Key and Certificate Authority
(see bellow instructions) and for declaring with the 
"hdp.private\_key\_location" and "hdp.cacert\_location" property.

It is also recommendate to configure the 
"hdp.core\_site['ssl.server.truststore.password']" and 
"hdp.core\_site['ssl.server.keystore.password']" passwords or they will default to
"ryba123".

Here's how to generate your own Private Key and Certificate Authority:

```
openssl genrsa -out hadoop.key 2048
openssl req -x509 -new -key hadoop.key -days 300 -out hadoop.pem -subj "/C=FR/ST=IDF/L=Paris/O=Adaltas/CN=adaltas.com/emailAddress=david@adaltas.com"
```

You can see the content of the root CA certificate with the command:

```
openssl x509 -text -noout -in hadoop.pem
```

You can list the content of the keystore with the command:

```
keytool -list -v -keystore truststore
keytool -list -v -keystore keystore -alias hadoop
```

[hdp_ssl]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1-latest/bk_reference/content/ch_wire-https.html

      @config.ryba.ssl ?= {}
      ssl_client = @config.ryba.ssl_client ?= {}
      ssl_server = @config.ryba.ssl_server ?= {}
      throw new Error 'Required property "ryba.ssl.cacert"' unless @config.ryba.ssl.cacert
      throw new Error 'Required property "ryba.ssl.cert"' unless @config.ryba.ssl.cert
      throw new Error 'Required property "ryba.ssl.key"' unless @config.ryba.ssl.key
      # SSL for HTTPS connection and RPC Encryption
      core_site['hadoop.ssl.require.client.cert'] ?= 'false'
      core_site['hadoop.ssl.hostname.verifier'] ?= 'DEFAULT'
      core_site['hadoop.ssl.keystores.factory.class'] ?= 'org.apache.hadoop.security.ssl.FileBasedKeyStoresFactory'
      core_site['hadoop.ssl.server.conf'] ?= 'ssl-server.xml'
      core_site['hadoop.ssl.client.conf'] ?= 'ssl-client.xml'
      ssl_client['ssl.client.truststore.location'] ?= "#{ryba.hadoop_conf_dir}/truststore"
      ssl_client['ssl.client.truststore.password'] ?= 'ryba123'
      ssl_client['ssl.client.truststore.type'] ?= 'jks'
      ssl_server['ssl.server.keystore.location'] ?= "#{ryba.hadoop_conf_dir}/keystore"
      ssl_server['ssl.server.keystore.password'] ?= 'ryba123'
      ssl_server['ssl.server.keystore.type'] ?= 'jks'
      ssl_server['ssl.server.keystore.keypassword'] ?= 'ryba123'
      ssl_server['ssl.server.truststore.location'] ?= "#{ryba.hadoop_conf_dir}/truststore"
      ssl_server['ssl.server.truststore.password'] ?= 'ryba123'
      ssl_server['ssl.server.truststore.type'] ?= 'jks'

## Dependencies

    path = require 'path'
    quote = require 'regexp-quote'
