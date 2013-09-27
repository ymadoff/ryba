
hdp = require './hdp'
each = require 'each'
mecano = require 'mecano'
superexec = require 'superexec'
connect = require 'superexec/lib/connect'
misc = require 'mecano/lib/misc'
properties = require './hadoop/lib/properties'
mkprincipal = require './krb5/lib/mkprincipal'
krb5_client = require './krb5_client'

module.exports = []
module.exports.push 'histi/actions/hdp'
module.exports.push 'histi/actions/hdp_hive'

###

Creating Service Principals and Keytab Files for Hadoop
http://incubator.apache.org/ambari/1.2.5/installing-hadoop-using-ambari/content/ambari-kerb-1-4.html
Ambari suggest to create three special principals (ambari-user, 
hdfs, hbase) where we do not need the FQDN appended to the primary name.

Hadoop and Kerberos:
http://hadoop.apache.org/docs/r1.2.0/HttpAuthentication.html

Hortonworks Kerberos Principals And Keytab Files:
http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.2/bk_gsInstaller/content/ch_gsInstaller-chp6_3.html

http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.1/bk_installing_manually_book/content/rpm-chap14-1-4.html

Error
*   Message: kadmin: GSS-API (or Kerberos) error while initializing kadmin interface
    Possible solution: synchronize date with NTP
*   Message: ERROR org.apache.hadoop.hdfs.server.datanode.DataNode: java.lang.RuntimeException: Cannot start secure cluster without privileged resources.
    Solution: you need to start the datanode as root
###
module.exports.push (ctx) ->
  hdp.configure ctx
  ctx.config.hdp.force_keytabs_generation ?= false
  krb5_client.configure ctx

module.exports.push (ctx, next) ->
  @name 'HDP Kerberos # Service Principals'
  @timeout -1
  server = ctx.servers(action: 'histi/actions/krb5_server')[0]
  {hdfs_user} = ctx.config.hdp
  {realm, kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5_client
  ctx.mkdir
    destination: '/etc/security/keytabs'
    uid: 'root'
    gid: 'hadoop'
    mode: '0750'
  , (err, created) ->
    ctx.log 'Creating Service Principals'
    principals = []
    if ctx.config.hdp.namenode
      principals.push
        principal: "#{hdfs_user}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/hdfs.headless.keytab"
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        admin_server: admin_server
        uid: 'hdfs'
        gid: 'hadoop'
        mode: '600'
        not_if_exists: "/etc/security/keytabs/hdfs.service.keytab"
    if ctx.config.hdp.namenode or ctx.config.hdp.secondary_namenode
      principals.push
        principal: "nn/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/nn.service.keytab"
        uid: 'hdfs'
        gid: 'hadoop'
        not_if_exists: "/etc/security/keytabs/nn.service.keytab"
    if ctx.config.hdp.namenode or ctx.config.hdp.datanode or ctx.config.hdp.secondary_namenode or ctx.config.hdp.oozie or ctx.config.hdp.webhcat
      principals.push
        principal: "HTTP/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/spnego.service.keytab"
        uid: 'hdfs'
        gid: 'hadoop'
        mode: '660' # need rw access for hadoop and mapred users
        not_if_exists: "/etc/security/keytabs/spnego.service.keytab"
    if ctx.config.hdp.jobtraker
      principals.push
        principal: "jt/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/jt.service.keytab"
        uid: 'mapred'
        gid: 'hadoop'
        not_if_exists: "/etc/security/keytabs/jt.service.keytab"
    if ctx.config.hdp.tasktraker
      principals.push
        principal: "tt/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/tt.service.keytab"
        uid: 'mapred'
        gid: 'hadoop'
        not_if_exists: "/etc/security/keytabs/tt.service.keytab"
    if ctx.config.hdp.datanode
      principals.push
        principal: "dn/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/dn.service.keytab"
        uid: 'hdfs'
        gid: 'hadoop'
        not_if_exists: "/etc/security/keytabs/dn.service.keytab"
    if ctx.config.hdp.hbase_master or ctx.config.hdp.hbase_regionserver
      principals.push
        principal: "hbase/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/hbase.service.keytab"
        uid: 'hbase'
        gid: 'hadoop'
        not_if_exists: "/etc/security/keytabs/hbase.service.keytab"
    if ctx.config.hdp.zookeeper
      principals.push
        principal: "zookeeper/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/zookeeper.service.keytab"
        uid: 'zookeeper'
        gid: 'hadoop'
        not_if_exists: "/etc/security/keytabs/zookeeper.service.keytab"
    if ctx.config.hdp.hive_metastore
      principals.push
        principal: "hive/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/hive.service.keytab"
        uid: 'hive'
        gid: 'hadoop'
        not_if_exists: "/etc/security/keytabs/hive.service.keytab"
    if ctx.config.hdp.hcatalog_server
      principals.push
        principal: "hcat/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/hcat.service.keytab"
        uid: 'hcat'
        gid: 'hadoop'
        not_if_exists: "/etc/security/keytabs/hcat.service.keytab"
    if ctx.config.hdp.oozie
      principals.push
        principal: "oozie/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/oozie.service.keytab"
        uid: 'oozie'
        gid: 'hadoop'
        not_if_exists: "/etc/security/keytabs/oozie.service.keytab"
    for principal in principals
      principal.ssh = ctx.ssh
      principal.log = ctx.log
      principal.stdout = ctx.log.out
      principal.stderr = ctx.log.err
      principal.kadmin_principal = kadmin_principal
      principal.kadmin_password = kadmin_password
      principal.admin_server = admin_server
    mkprincipal parallel: false, principals, (err, created) ->
      return next err if err
      next null, if created then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Kerberos # Java JCE'
  @timeout -1
  ctx.log "Download jce-6 Security JARs"
  {java_home} = ctx.config.hdp
  ctx.upload [
    source: "#{__dirname}/../lib/jce_policy-6/local_policy.jar"
    destination: "#{java_home}/jre/lib/security/local_policy.jar"
    binary: true
    not_if_exists: true
  ,
    source: "#{__dirname}/../lib/jce_policy-6/US_export_policy.jar"
    destination: "#{java_home}/jre/lib/security/US_export_policy.jar"
    binary: true
    not_if_exists: true
  ], (err, downloaded) ->
    next err, if downloaded then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Kerberos # Configure Core'
  {realm} = ctx.config.krb5_client
  properties.read ctx.ssh, '/etc/hadoop/conf/core-site.xml', (err, kv) ->
    return next err if err
    hosts = ctx.config.servers.map( (server) -> server.host ).join(',')
    core = {}
    # Set the authentication for the cluster. Valid values are: simple or kerberos
    core['hadoop.security.authentication'] ?= 'kerberos'
    # This is an [OPTIONAL] setting. If not set, defaults to 
    # authentication.authentication= authentication only; the client and server 
    # mutually authenticate during connection setup.integrity = authentication 
    # and integrity; guarantees the integrity of data exchanged between client 
    # and server aswell as authentication.privacy = authentication, integrity, 
    # and confidentiality; guarantees that data exchanged between client andserver 
    # is encrypted and is not readable by a “man in the middle”.
    core['hadoop.rpc.protection'] ?= 'authentication'
    # Enable authorization for different protocols.
    core['hadoop.security.authorization'] ?= 'true'
    # The mapping from Kerberos principal names to local OS user names.
    core['hadoop.security.auth_to_local'] ?= """
      RULE:[2:$1@$0]([jt]t@.*#{realm})s/.*/mapred/
      RULE:[2:$1@$0]([nd]n@.*#{realm})s/.*/hdfs/
      DEFAULT
      """
    # Allow the superuser hive to impersonate any members of the group users. Required only when installing Hive.
    core['hadoop.proxyuser.hive.groups'] ?= '*'
    # Hostname from where superuser hive can connect. Required 
    # only when installing Hive.
    # core['hadoop.proxyuser.hive.hosts'] ?= hosts
    core['hadoop.proxyuser.hive.hosts'] ?= '*'
    # Allow the superuser oozie to impersonate any members of 
    # the group users. Required only when installing Oozie.
    core['hadoop.proxyuser.oozie.groups'] ?= '*'
    # Hostname from where superuser oozie can connect. Required 
    # only when installing Oozie.
    # core['hadoop.proxyuser.oozie.hosts'] ?= hosts
    core['hadoop.proxyuser.oozie.hosts'] ?= '*'
    # Hostname from where superuser hcat can connect. Required 
    # only when installing WebHCat.
    # core['hadoop.proxyuser.hcat.hosts'] ?= hosts
    core['hadoop.proxyuser.hcat.hosts'] ?= '*'
    # Hostname from where superuser HTTP can connect.
    core['hadoop.proxyuser.HTTP.groups'] ?= '*'
    # Allow the superuser hcat to impersonate any members of the 
    # group users. Required only when installing WebHCat.
    core['hadoop.proxyuser.hcat.groups'] ?= '*'
    # Hostname from where superuser hcat can connect. This is 
    # required only when installing webhcat on the cluster.
    # core['hadoop.proxyuser.hcat.hosts'] ?= hosts
    core['hadoop.proxyuser.hcat.hosts'] ?= '*'
    modified = false
    for k, v of core
      modified = true if kv[k] isnt v
      kv[k] = v
    return next null, ctx.PASS unless modified
    properties.write ctx.ssh, '/etc/hadoop/conf/core-site.xml', kv, (err) ->
      next err, ctx.OK
      # ctx.service
      #   name: 
      # On all secure DataNodes, you must set the user to run the DataNode as after dropping privileges.
      # export HADOOP_SECURE_DN_USER=$HDFS_USER
      # Optionally, you can allow that user to access the directories where PID and log files are stored. For example:
      # export HADOOP_SECURE_DN_PID_DIR=/var/run/hadoop/$HADOOP_SECURE_DN_USER
      # export HADOOP_SECURE_DN_LOG_DIR=/var/run/hadoop/$HADOOP_SECURE_DN_USER

###
Configure Web
-------------

This action follow the ["Authentication for Hadoop HTTP web-consoles" 
recommandations](http://hadoop.apache.org/docs/r1.2.1/HttpAuthentication.html).
###
module.exports.push (ctx, next) ->
  @name 'HDP Kerberos # Configure Web'
  {krb5_client, realm} = ctx.config.krb5_client
  domain = ctx.config.servers.filter( (server) -> server.hdp?.namenode )[0].host
  ctx.execute
    cmd: 'dd if=/dev/urandom of=/etc/hadoop/hadoop-http-auth-signature-secret bs=1024 count=1'
    not_if_exists: '/etc/hadoop/hadoop-http-auth-signature-secret'
  , (err, executed) ->
    return next err if err
    ctx.hconfigure
      destination: '/etc/hadoop/conf/core-site.xml'
      properties:
        'hadoop.http.filter.initializers': 'org.apache.hadoop.security.AuthenticationFilterInitializer'
        'hadoop.http.authentication.type': 'kerberos'
        'hadoop.http.authentication.token.validity': 36000
        'hadoop.http.authentication.signature.secret.file': '/etc/hadoop/hadoop-http-auth-signature-secret'
        'hadoop.http.authentication.cookie.domain': domain
        'hadoop.http.authentication.simple.anonymous.allowed': 'false'
        # For some reason, _HOST isnt leverage
        'hadoop.http.authentication.kerberos.principal': "HTTP/#{ctx.config.host}@#{realm}"
        'hadoop.http.authentication.kerberos.keytab': '/etc/security/keytabs/spnego.service.keytab'
    , (err, configured) ->
      next err, if configured then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Kerberos # Configure HDFS'
  {realm} = ctx.config.krb5_client
  properties.read ctx.ssh, '/etc/hadoop/conf/hdfs-site.xml', (err, kv) ->
    return next err if err
    namenode = ctx.config.servers.filter( (server) -> server.hdp?.namenode )[0].host
    secondary_namenode = ctx.config.servers.filter( (server) -> server.hdp?.secondary_namenode )[0].host
    hdfs = {}
    # If "true", access tokens are used as capabilities
    # for accessing datanodes. If "false", no access tokens are checked on
    # accessing datanodes.
    hdfs['dfs.block.access.token.enable'] ?= 'true'
    # Kerberos principal name for the NameNode
    hdfs['dfs.namenode.kerberos.principal'] ?= "nn/_HOST@#{realm}"
    # Kerberos principal name for the secondary NameNode.
    hdfs['dfs.secondary.namenode.kerberos.principal'] ?= "nn/_HOST@#{realm}"
    # Address of secondary namenode web server
    hdfs['dfs.secondary.http.address'] ?= "#{secondary_namenode}:50090"
    # The https port where secondary-namenode binds
    hdfs['dfs.secondary.https.port'] ?= '50490'
    # The HTTP Kerberos principal used by Hadoop-Auth in the HTTP 
    # endpoint. The HTTP Kerberos principal MUST start with 'HTTP/' 
    # per Kerberos HTTP SPNEGO specification. 
    hdfs['dfs.web.authentication.kerberos.principal'] ?= "HTTP/_HOST@#{realm}"
    # The Kerberos keytab file with the credentials for the HTTP 
    # Kerberos principal used by Hadoop-Auth in the HTTP endpoint.
    hdfs['dfs.web.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab'
    # The Kerberos principal that the DataNode runs as. "_HOST" is replaced by the real host name.  
    hdfs['dfs.datanode.kerberos.principal'] ?= "dn/_HOST@#{realm}"
    # Combined keytab file containing the NameNode service and host principals.
    hdfs['dfs.namenode.keytab.file'] ?= '/etc/security/keytabs/nn.service.keytab'
    # Combined keytab file containing the NameNode service and host principals.
    hdfs['dfs.secondary.namenode.keytab.file'] ?= '/etc/security/keytabs/nn.service.keytab'
    # The filename of the keytab file for the DataNode.
    hdfs['dfs.datanode.keytab.file'] ?= '/etc/security/keytabs/dn.service.keytab'
    # The https port where NameNode binds
    hdfs['dfs.https.port'] ?= '50470'
    # The https address where namenode binds. Example: ip-10-111-59-170.ec2.internal:50470
    hdfs['dfs.https.address'] ?= "#{namenode}:50470"
    # # Default to ${dfs.web.authentication.kerberos.principal}, but documented in hdp 1.3.2 manual install
    hdfs['dfs.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/_HOST@#{realm}"
    # # Default to ${dfs.web.authentication.kerberos.principal}, but documented in hdp 1.3.2 manual install
    hdfs['dfs.secondary.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/_HOST@#{realm}"
    # The address, with a privileged port - any port number under 1023. Example: 0.0.0.0:1019
    hdfs['dfs.datanode.address'] ?= '0.0.0.0:1019'
    # The address, with a privileged port - any port number under 1023. Example: 0.0.0.0:1022
    hdfs['dfs.datanode.http.address'] ?= '0.0.0.0:1022'
    # NOT DOCUMENTED
    # hdfs['dfs.namenode.kerberos.https.principal'] = "host/_HOST@EXAMPLE.COM"
    # hdfs['dfs.secondary.namenode.kerberos.https.principal'] = "host/_HOST@EXAMPLE.COM"
    modified = false
    for k, v of hdfs
      modified = true if kv[k] isnt v
      kv[k] = v
    return next null, ctx.PASS unless modified
    properties.write ctx.ssh, '/etc/hadoop/conf/hdfs-site.xml', kv, (err) ->
      next err, ctx.OK

module.exports.push (ctx, next) ->
  @name 'HDP Kerberos # Configure MapReduce'
  {realm} = ctx.config.krb5_client
  properties.read ctx.ssh, '/etc/hadoop/conf/mapred-site.xml', (err, kv) ->
    return next err if err
    mapred = {}
    # Kerberos principal name for the JobTracker
    mapred['mapreduce.jobtracker.kerberos.principal'] ?= "jt/_HOST@#{realm}"
    # Kerberos principal name for the TaskTracker."_HOST" is replaced by the host name of the TaskTracker. 
    mapred['mapreduce.tasktracker.kerberos.principal'] ?= "tt/_HOST@#{realm}"
    # The keytab for the JobTracker principal.
    mapred['mapreduce.jobtracker.keytab.file'] ?= '/etc/security/keytabs/jt.service.keytab'
    # The filename of the keytab for the TaskTracker
    mapred['mapreduce.tasktracker.keytab.file'] ?= '/etc/security/keytabs/tt.service.keytab'
    # Kerberos principal name for JobHistory. This must map to the same user as the JobTracker user (mapred).
    mapred['mapreduce.jobhistory.kerberos.principal'] ?= "jt/_HOST@#{realm}"
    # The keytab for the JobHistory principal.
    mapred['mapreduce.jobhistory.keytab.file'] ?= '/etc/security/keytabs/jt.service.keytab'
    modified = false
    for k, v of mapred
      modified = true if kv[k] isnt v
      kv[k] = v
    return next null, ctx.PASS unless modified
    properties.write ctx.ssh, '/etc/hadoop/conf/mapred-site.xml', kv, (err) ->
      next err, ctx.OK

module.exports.push (ctx, next) ->
  @name 'HDP Kerberos # Configure Hive/HCat'
  {realm} = ctx.config.krb5_client
  ctx.hconfigure
    destination: '/etc/hive/conf/hive-site.xml'
    properties:
      # If true, the metastore thrift interface will be secured with
      # SASL. Clients must authenticate with Kerberos.
      'hive.metastore.sasl.enabled': "true"
      # The path to the Kerberos Keytab file containing the metastore
      # thrift server's service principal.
      'hive.metastore.kerberos.keytab.file': "/etc/security/keytabs/hive.service.keytab"
      # 'hive.metastore.kerberos.keytab.file': "/etc/security/keytabs/hcat.service.keytab"
      # The service principal for the metastore thrift server. The
      # special string _HOST will be replaced automatically with the correct  hostname.
      'hive.metastore.kerberos.principal': "hive/_HOST@#{realm}"
      # 'hive.metastore.kerberos.principal': "hcat/#{ctx.config.host}@#{realm}"
      # Authentication type
      'hive.server2.authentication': "KERBEROS"
      # The service principal for the HiveServer2. If _HOST
      # is used as the hostname portion, it will be replaced
      # with the actual hostname of the running instance.
      'hive.server2.authentication.kerberos.principal': "hive/_HOST@#{realm}"
      # 'hive.server2.authentication.kerberos.principal': "hcat/#{ctx.config.host}@#{realm}"
      # The keytab for the HiveServer2 service principal
      'hive.server2.authentication.kerberos.keytab': "/etc/security/keytabs/hive.service.keytab"
      # 'hive.server2.authentication.kerberos.keytab': "/etc/security/keytabs/hcat.service.keytab"
  , (err, configured) ->
    next err, if configured then ctx.OK else ctx.PASS

