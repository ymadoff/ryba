
# Hadoop Core

The [Hadoop distribution](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.4/bk_getting-started-guide/content/ch_hdp1_getting_started_chp2_1.html) used is the Hortonwork distribution named HDP. The
installation is leveraging the Yum repositories. [Individual tarballs][tar]
are also available as an alternative with the benefit of including the source
code.


*   http://bigdataprocessing.wordpress.com/2013/07/30/hadoop-rack-awareness-and-configuration/

[tar]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.9.1/bk_installing_manually_book/content/rpm-chap13.html

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    # Install kerberos clients to create/test new HDFS and Yarn principals
    module.exports.push 'masson/core/krb5_client'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/lib/base'
    module.exports.push 'ryba/lib/hconfigure'
    module.exports.push 'ryba/lib/hdp_select'

## Configuration

*   `ryba.static_host` (boolean)
    Write the host name of the server instead of the Hadoop "_HOST"
    placeholder accross all the configuration files, default to false.
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

    module.exports.configure = (ctx) ->
      require('../ganglia/collector').configure ctx
      require('../graphite/carbon').configure ctx
      return if ctx.core_configured
      ctx.core_configured = true
      require('masson/commons/java').configure ctx
      require('masson/core/krb5_client').configure ctx
      require('../lib/base').configure ctx
      {realm, ganglia, graphite} = ctx.config.ryba
      ryba = ctx.config.ryba ?= {}
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
      ryba.hdfs.user.limits.nproc ?= true
      ryba.hdfs.user.limits.nofile ?= true
      # Kerberos user for hdfs
      ryba.hdfs.krb5_user ?= {}
      ryba.hdfs.krb5_user.principal ?= "#{ryba.hdfs.user.name}@#{realm}"
      ryba.hdfs.krb5_user.password ?= 'password'
      # Unix user for yarn
      ryba.yarn.user ?= {}
      ryba.yarn.user = name: ryba.yarn.user if typeof ryba.yarn.user is 'string'
      ryba.yarn.user.name ?= 'yarn'
      ryba.yarn.user.system ?= true
      ryba.yarn.user.groups ?= 'hadoop'
      ryba.yarn.user.comment ?= 'Hadoop YARN User'
      ryba.yarn.user.home ?= '/var/lib/hadoop-yarn'
      ryba.yarn.user.limits ?= {}
      ryba.yarn.user.limits.nproc ?= true
      ryba.yarn.user.limits.nofile ?= true
      # Unix user for mapred
      ryba.mapred.user ?= {}
      ryba.mapred.user = name: ryba.mapred.user if typeof ryba.mapred.user is 'string'
      ryba.mapred.user.name ?= 'mapred'
      ryba.mapred.user.system ?= true
      ryba.mapred.user.groups ?= 'hadoop'
      ryba.mapred.user.comment ?= 'Hadoop MapReduce User'
      ryba.mapred.user.home ?= '/var/lib/hadoop-mapreduce'
      ryba.mapred.user.limits ?= {}
      ryba.mapred.user.limits.nproc ?= 64000
      ryba.mapred.user.limits.nofile ?= 64000
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
      ryba.active_nn ?= false
      throw new Error "Invalid Service Name" unless ryba.nameservice
      namenodes = ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
      # throw new Error "Need at least 2 namenodes" if namenodes.length < 2
      # active_nn_hosts = ctx.config.servers.filter( (server) -> server.ryba?.active_nn ).map( (server) -> server.host )
      # standby_nn_hosts = ctx.config.servers.filter( (server) -> ! server.ryba?.active_nn ).map( (server) -> server.host )
      standby_nn_hosts = namenodes.filter( (server) -> ! ctx.config.servers[server].ryba?.active_nn )
      # throw new Error "Invalid Number of Passive NameNodes: #{standby_nn_hosts.length}" unless standby_nn_hosts.length is 1
      ryba.standby_nn_host = standby_nn_hosts[0]
      ryba.static_host =
        if ryba.static_host and ryba.static_host isnt '_HOST'
        then ctx.config.host
        else '_HOST'
      # Configuration
      core_site = ryba.core_site ?= {}
      core_site['io.compression.codecs'] ?= "org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.SnappyCodec"
      unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
        core_site['fs.defaultFS'] ?= "hdfs://#{namenodes[0]}:8020"
      else
        core_site['fs.defaultFS'] ?= "hdfs://#{ryba.nameservice}:8020"
        active_nn_hosts = namenodes.filter( (server) -> ctx.config.servers[server].ryba?.active_nn )
        throw new Error "Invalid Number of Active NameNodes: #{active_nn_hosts.length}" unless active_nn_hosts.length is 1
        ryba.active_nn_host = active_nn_hosts[0]
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
      core_jars = ctx.config.ryba.core_jars ?= {}
      for k, v of core_jars
        throw Error 'Invalid core_jars source' unless v.source
        v.match ?= "#{k}-*.jar"
        v.filename = path.basename v.source
      # Get ZooKeeper Quorum
      zoo_ctxs = ctx.contexts 'ryba/zookeeper/server', require('../zookeeper/server').configure
      zookeeper_quorum = for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
      core_site['ha.zookeeper.quorum'] ?= zookeeper_quorum
      # Topology
      # http://ofirm.wordpress.com/2014/01/09/exploring-the-hadoop-network-topology/
      core_site['net.topology.script.file.name'] ?= "#{ryba.hadoop_conf_dir}/rack_topology.sh"

Configuration for HTTP

      core_site['hadoop.http.filter.initializers'] ?= 'org.apache.hadoop.security.AuthenticationFilterInitializer'
      core_site['hadoop.http.authentication.type'] ?= 'kerberos'
      core_site['hadoop.http.authentication.token.validity'] ?= '36000'
      core_site['hadoop.http.authentication.signature.secret.file'] ?= '/etc/hadoop/hadoop-http-auth-signature-secret'
      core_site['hadoop.http.authentication.simple.anonymous.allowed'] ?= 'false'
      core_site['hadoop.http.authentication.kerberos.principal'] ?= "HTTP/#{ryba.static_host}@#{ryba.realm}"
      core_site['hadoop.http.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab'
      # Cluster domain
      unless core_site['hadoop.http.authentication.cookie.domain']
        domains = ctx.hosts_with_module('ryba/hadoop/core').map( (host) -> host.split('.').slice(1).join('.') ).filter( (el, pos, self) -> self.indexOf(el) is pos )
        throw Error "Multiple domains, set 'hadoop.http.authentication.cookie.domain' manually" if domains.length isnt 1
        core_site['hadoop.http.authentication.cookie.domain'] = domains[0]

Configuration for proxy users

      core_site['hadoop.security.auth_to_local'] ?= """

            RULE:[2:$1@$0]([rn]m@.*)s/.*/yarn/
            RULE:[2:$1@$0](jhs@.*)s/.*/mapred/
            RULE:[2:$1@$0]([nd]n@.*)s/.*/hdfs/
            RULE:[2:$1@$0](hm@.*)s/.*/hbase/
            RULE:[2:$1@$0](rs@.*)s/.*/hbase/
            DEFAULT

        """
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

      hadoop_metrics = ctx.config.ryba.hadoop_metrics ?= {}
      # default sampling period, in seconds
      hadoop_metrics['*.period'] ?= '60'
      # File sink
      if hadoop_metrics['*.sink.file.class'] is 'org.apache.hadoop.metrics2.sink.FileSink'
        # hadoop_metrics['*.sink.file.class'] ?= 'org.apache.hadoop.metrics2.sink.FileSink'
        hadoop_metrics['*.sink.file.filename'] ?= 'metrics.out'
        hadoop_metrics['namenode.sink.file.filename'] ?= 'namenode-metrics.out'
        hadoop_metrics['datanode.sink.file.filename'] ?= 'datanode-metrics.out'
        hadoop_metrics['resourcemanager.sink.file.filename'] ?= 'resourcemanager-metrics.out'
        hadoop_metrics['nodemanager.sink.file.filename'] ?= 'nodemanager-metrics.out'
        hadoop_metrics['mrappmaster.sink.file.filename'] ?= 'mrappmaster-metrics.out'
        hadoop_metrics['jobhistoryserver.sink.file.filename'] ?= 'jobhistoryserver-metrics.out'
      # Ganglia sink, accepted properties are "servers" and "supportsparse"
      [ganglia_ctx] =  ctx.contexts 'ryba/ganglia/collector', require('../ganglia/collector').configure
      if ganglia_ctx and (hadoop_metrics['*.sink.ganglia.class'] or hadoop_metrics['*.sink.ganglia.class'] is undefined)
        hadoop_metrics['*.sink.ganglia.class'] ?= 'org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31'
        hadoop_metrics['*.sink.ganglia.period'] ?= '10'
        hadoop_metrics['*.sink.ganglia.supportsparse'] ?= 'true' # Setting to "true" helps in reducing bandwith (see "Practical Hadoop Security")
        hadoop_metrics['*.sink.ganglia.slope'] ?= 'jvm.metrics.gcCount=zero,jvm.metrics.memHeapUsedM=both'
        hadoop_metrics['*.sink.ganglia.dmax'] ?= 'jvm.metrics.threadsBlocked=70,jvm.metrics.memHeapUsedM=40' # How long a particular value will be retained
        if ctx.has_module 'ryba/hadoop/hdfs_nn'
          hadoop_metrics['namenode.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.nn_port}"
        if ctx.has_module 'ryba/hadoop/yarn_rm'
          hadoop_metrics['resourcemanager.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.rm_port}"
        if ctx.has_module 'ryba/hadoop/hdfs_dn'
          hadoop_metrics['datanode.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.nn_port}"
        if ctx.has_module 'ryba/hadoop/yarn_nm'
          hadoop_metrics['nodemanager.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.nn_port}"
          hadoop_metrics['maptask.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.nn_port}"
          hadoop_metrics['reducetask.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.nn_port}"
        # if ctx.has_module 'ryba/hadoop/hdfs_jn'
        #   hadoop_metrics['journalnode.sink.ganglia.servers']
        # if ctx.has_module 'ryba/hadoop/mapred_jhs'
        #   hadoop_metrics['historyserver.sink.ganglia.servers']
        # if ctx.has_module 'ryba/storm/nimbus'
        #   hadoop_metrics['nimbus.sink.ganglia.servers']
        # if ctx.has_module 'ryba/storm/supervisor'
        #   hadoop_metrics['supervisor.sink.ganglia.servers']
      # Graphite sink, accepted properties are "server_host", "server_port" and "metrics_prefix"
      [graphite_ctx] =  ctx.contexts 'ryba/graphite/collector'
      if graphite_ctx and (hadoop_metrics['*.sink.graphite.class'] or hadoop_metrics['*.sink.graphite.class'] is undefined)
        hadoop_metrics['*.sink.graphite.class'] ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'
        hadoop_metrics['*.sink.graphite.period'] ?= '10'
        if ctx.has_module 'ryba/hadoop/hdfs_nn'
          hadoop_metrics['namenode.sink.graphite.server_host'] ?= "#{graphite_ctx.config.host}"
          hadoop_metrics['namenode.sink.graphite.server_port'] ?= "#{graphite_ctx.config.ryba.graphite.carbon_aggregator_port}"
        if ctx.has_module 'ryba/hadoop/yarn_rm'
          hadoop_metrics['resourcemanager.sink.graphite.server_host'] ?= "#{graphite_ctx.config.host}"
          hadoop_metrics['resourcemanager.sink.graphite.server_port'] ?= "#{graphite_ctx.config.ryba.graphite.carbon_aggregator_port}"
        if ctx.has_module 'ryba/hadoop/hdfs_dn'
          hadoop_metrics['datanode.sink.graphite.server_host'] ?= "#{graphite_ctx.config.host}"
          hadoop_metrics['datanode.sink.graphite.server_port'] ?= "#{graphite_ctx.config.ryba.graphite.carbon_aggregator_port}"
        if ctx.has_module 'ryba/hadoop/yarn_nm'
          hadoop_metrics['nodemanager.sink.graphite.server_host'] ?= "#{graphite_ctx.config.host}"
          hadoop_metrics['nodemanager.sink.graphite.server_port'] ?= "#{graphite_ctx.config.ryba.ganglia.nn_port}"
          hadoop_metrics['maptask.sink.graphite.server_host'] ?= "#{graphite_ctx.config.host}"
          hadoop_metrics['maptask.sink.graphite.server_port'] ?= "#{graphite_ctx.config.ryba.graphite.carbon_aggregator_port}"
          hadoop_metrics['reducetask.sink.graphite.server_host'] ?= "#{graphite_ctx.config.host}"
          hadoop_metrics['reducetask.sink.graphite.server_port'] ?= "#{graphite_ctx.config.ryba.graphite.carbon_aggregator_port}"
        if ctx.has_module 'ryba/hadoop/hdfs_jn'
          hadoop_metrics['journalnode.sink.graphite.server_host']
        if ctx.has_module 'ryba/hadoop/mapred_jhs'
          hadoop_metrics['historyserver.sink.graphite.server_host']
        # if ctx.has_module 'ryba/storm/nimbus'
        #   hadoop_metrics['nimbus.sink.graphite.server_host']
        # if ctx.has_module 'ryba/storm/supervisor'
        #   hadoop_metrics['supervisor.sink.graphite.server_host']

## Users & Groups

By default, the "hadoop-client" package rely on the "hadoop", "hadoop-hdfs",
"hadoop-mapreduce" and "hadoop-yarn" dependencies and create the following
entries:

```bash
cat /etc/passwd | grep hadoop
hdfs:x:496:497:Hadoop HDFS:/var/lib/hadoop-hdfs:/bin/bash
yarn:x:495:495:Hadoop Yarn:/var/lib/hadoop-yarn:/bin/bash
mapred:x:494:494:Hadoop MapReduce:/var/lib/hadoop-mapreduce:/bin/bash
cat /etc/group | egrep "hdfs|yarn|mapred"
hadoop:x:498:hdfs,yarn,mapred
hdfs:x:497:
yarn:x:495:
mapred:x:494:
```

Note, the package "hadoop" will also install the "dbus" user and group which are
not handled here.

    module.exports.push header: 'Hadoop Core # Users & Groups', handler: ->
      {hadoop_group, hdfs, yarn, mapred} = @config.ryba
      @group [hadoop_group, hdfs.group, yarn.group, mapred.group]
      @user [hdfs.user, yarn.user, mapred.user]

    module.exports.push header: 'Hadoop Core # Topology', handler: ->
      {hdfs, hadoop_conf_dir, hadoop_group} = @config.ryba
      h_ctxs = @contexts modules: ['ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_nm']
      topology = []
      for h_ctx in h_ctxs
        rack = if h_ctx.config.ryba?.rack? then h_ctx.config.ryba.rack else ''
        # topology.push "#{host}  #{rack}"
        topology.push "#{h_ctx.config.ip}  #{rack}"
      topology = topology.join("\n")
      @upload
        destination: "#{hadoop_conf_dir}/rack_topology.sh"
        source: "#{__dirname}/../resources/rack_topology.sh"
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
        backup: true
      @write
        destination: "#{hadoop_conf_dir}/rack_topology.data"
        content: topology
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
        backup: true
        eof: true

## Test User

Create a Unix and Kerberos test user, by default "ryba". Its HDFS home directory
will be created by one of the datanode.

    module.exports.push header: 'Hadoop Core # User Test', timeout: -1, handler: ->
      {krb5_user, user, group, security, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      # ryba group and user may already exist in "/etc/passwd" or in any sssd backend
      @group group
      @user user
      @krb5_addprinc merge
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , krb5_user

## SPNEGO

Create the SPNEGO service principal in the form of "HTTP/{host}@{realm}" and place its
keytab inside "/etc/security/keytabs/spnego.service.keytab" with ownerships set to "hdfs:hadoop"
and permissions set to "0660". We had to give read/write permission to the group because the
same keytab file is for now shared between hdfs and yarn services.

    module.exports.push header: 'Hadoop Core # SPNEGO', handler: module.exports.spnego = ->
      {hdfs, hadoop_group, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: "HTTP/#{@config.host}@#{realm}"
        randkey: true
        keytab: '/etc/security/keytabs/spnego.service.keytab'
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o660 # need rw access for hadoop and mapred users
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      @execute # Validate keytab access by the hdfs user
        cmd: "su -l #{hdfs.user.name} -c \"klist -kt /etc/security/keytabs/spnego.service.keytab\""
        if: -> @status -1

    module.exports.push header: 'Hadoop Core # Keytabs', timeout: -1, handler: ->
      {hadoop_group} = @config.ryba
      @mkdir
        destination: '/etc/security/keytabs'
        uid: 'root'
        gid: hadoop_group.name
        mode: 0o0755

    module.exports.push header: 'Hadoop Core # Compression', timeout: -1, handler: ->
      { hadoop_conf_dir } = @config.ryba
      @service name: 'snappy'
      @service name: 'snappy-devel'
      @execute
        cmd: 'ln -sf /usr/lib64/libsnappy.so /usr/lib/hadoop/lib/native/.'
        if: -> @status(-1) or @status(-2)
      @service
        name: 'lzo'
      @service
        name: 'lzo-devel'
      @service
        name: 'hadoop-lzo'
      @service
        name: 'hadoop-lzo-native'

## Web UI

This action follow the ["Authentication for Hadoop HTTP web-consoles"
recommendations](http://hadoop.apache.org/docs/r1.2.1/HttpAuthentication.html).

    module.exports.push header: 'Hadoop Core # Web UI', handler: ->
      {core_site, realm} = @config.ryba
      @execute
        cmd: 'dd if=/dev/urandom of=/etc/hadoop/hadoop-http-auth-signature-secret bs=1024 count=1'
        unless_exists: '/etc/hadoop/hadoop-http-auth-signature-secret'

    module.exports.push 'ryba/hadoop/core_ssl'

## Dependencies


    fs = require 'ssh2-fs'
    path = require 'path'
    multimatch = require 'multimatch'
    mkcmd = require '../lib/mkcmd'
    {merge} = require 'mecano/lib/misc'
