
url = require 'url'
hconfigure = require './hadoop/lib/hconfigure'

module.exports = []
module.exports.push 'histi/actions/yum'
module.exports.push 'histi/actions/krb5_client' #kadmin must be present

###

Kerberos
--------

See official [Running Hadoop in Secure Mode](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode).

dn.service.keytab
  dn/full.qualified.domain.name@REALM.TLD
  host/full.qualified.domain.name@REALM.TLD

nn.service.keytab
  nn/full.qualified.domain.name@REALM.TLD
  host/full.qualified.domain.name@REALM.TLD

sn.service.keytab
  sn/full.qualified.domain.name@REALM.TLD
  host/full.qualified.domain.name@REALM.TLD
  
rm.service.keytab
  rm/full.qualified.domain.name@REALM.TLD
  host/full.qualified.domain.name@REALM.TLD

nm.service.keytab
  nm/full.qualified.domain.name@REALM.TLD
  host/full.qualified.domain.name@REALM.TLD

jhs.service.keytab
  jhs/full.qualified.domain.name@REALM.TLD
  host/full.qualified.domain.name@REALM.TLD
###
module.exports.push module.exports.configure = (ctx) ->
  require('./proxy').configure ctx
  ctx.config.hdp ?= {}
  ctx.config.hdp.format ?= false
  ctx.config.hdp.hadoop_conf_dir ?= '/etc/hadoop/conf'
  # Repository
  ctx.config.hdp.proxy = ctx.config.proxy.http_proxy if typeof ctx.config.hdp.http_proxy is 'undefined'
  ctx.config.hdp.hdp_repo ?= 'http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.0.5.0/hdp.repo'
  # Define the role
  ctx.config.hdp.namenode ?= false
  ctx.config.hdp.secondary_namenode ?= false
  ctx.config.hdp.datanode ?= false
  ctx.config.hdp.hbase_master ?= false
  ctx.config.hdp.hbase_regionserver ?= false
  ctx.config.hdp.zookeeper ?= false
  ctx.config.hdp.hcatalog_server ?= false
  ctx.config.hdp.oozie ?= false
  ctx.config.hdp.webhcat ?= false
  # Define Users and Groups
  ctx.config.hdp.hadoop_user ?= 'root'
  ctx.config.hdp.hadoop_group ?= 'hadoop'
  # Define Directories for Ecosystem Components
  ctx.config.hdp.sqoop_conf_dir ?= '/etc/sqoop/conf'
  # Options and configuration
  ctx.config.hdp.core ?= {}
  ctx.hconfigure = (options, callback) ->
    options.ssh = ctx.ssh if typeof options.ssh is 'undefined'
    options.log ?= ctx.log
    hconfigure options, callback

###
Repository
----------
Declare the HDP repository.
###
module.exports.push (ctx, next) ->
  {proxy, hdp_repo} = ctx.config.hdp
  # Is there a repo to download and install
  return next() unless hdp_repo
  @name 'HDP Core # Repository'
  modified = false
  @timeout -1
  do_hdp = ->
    ctx.log "Download #{hdp_repo} to /etc/yum.repos.d/hdp.repo"
    u = url.parse hdp_repo
    ctx[if u.protocol is 'http:' then 'download' else 'upload']
      source: hdp_repo
      destination: '/etc/yum.repos.d/hdp.repo'
      proxy: proxy
    , (err, downloaded) ->
      return next err if err
      modified = true if downloaded
      do_end()
  do_end = ->
      return next null, ctx.PASS unless modified
      ctx.log 'Clean up metadata and update'
      ctx.execute
        cmd: "yum clean metadata; yum update -y"
      , (err, executed) ->
        next err, ctx.OK
  do_hdp()

#http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-9.html
#http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode
module.exports.push (ctx, next) ->
  @name "HDP Core # Users & Groups"
  cmds = []
  {hadoop_group} = ctx.config.hdp
  ctx.execute
    cmd: "groupadd hadoop"
    code: 0
    code_skipped: 9
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP Core # Install"
  @timeout -1
  ctx.service [
  # wdavidw:
  # Installing the "hadoop" package as documented
  # generates "No package hadoop available", 
  # maybe because we cannot install directly this package
    name: 'hadoop-client'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP Core # Configuration"
  namenode = (ctx.config.servers.filter (s) -> s.hdp?.namenode)[0].host
  ctx.log "Namenode: #{namenode}"
  secondary_namenode = (ctx.config.servers.filter (s) -> s.hdp?.secondary_namenode)[0].host
  ctx.log "Secondary namenode: #{secondary_namenode}"
  jobhistoryserver = (ctx.config.servers.filter (s) -> s.hdp?.jobhistoryserver)[0].host
  # jobtraker = (ctx.config.servers.filter (s) -> s.hdp?.jobtraker)[0].host
  slaves = (ctx.config.servers.filter (s) -> s.hdp?.datanode).map (s) -> s.host
  { core, hadoop_conf_dir } = ctx.config.hdp
  modified = false
  do_core = ->
    ctx.log 'Configure core-site.xml'
    # NameNode hostname
    core['fs.defaultFS'] ?= "hdfs://#{namenode}:8020"
    # Determines where on the local filesystem the DFS secondary
    # name node should store the temporary images to merge.
    # If this is a comma-delimited list of directories then the image is
    # replicated in all of the directories for redundancy.
    # core['fs.checkpoint.edits.dir'] ?= fs_checkpoint_edit_dir.join ','
    # A comma separated list of paths. Use the list of directories from $FS_CHECKPOINT_DIR. 
    # For example, /grid/hadoop/hdfs/snn,sbr/grid1/hadoop/hdfs/snn,sbr/grid2/hadoop/hdfs/snn
    # core['fs.checkpoint.dir'] ?= fs_checkpoint_dir.join ','
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/core-site.xml"
      default: "#{__dirname}/hdp/core_hadoop/core-site.xml"
      local_default: true
      properties: core
      merge: true
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_core()

module.exports.push (ctx, next) ->
  @name 'HDP Core # Environnment'
  ctx.write
    destination: '/etc/profile.d/hadoop.sh'
    content: """
    #!/bin/bash
    export HADOOP_HOME=/usr/lib/hadoop
    """
    mode: '644'
  , (err, written) ->
    next null, if written then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP Core # Compression"
  @timeout -1
  modified = false
  { hadoop_conf_dir } = ctx.config.hdp
  do_snappy = ->
    ctx.service [
      name: 'snappy'
    ,
      name: 'snappy-devel'
    ], (err, serviced) ->
      return next err if err
      return do_lzo() unless serviced
      ctx.execute
        cmd: 'ln -sf /usr/lib64/libsnappy.so /usr/lib/hadoop/lib/native/.'
      , (err, executed) ->
        return next err if err
        modified = true
        do_lzo()
  do_lzo = ->
    ctx.service [
      name: 'lzo'
    ,
      name: 'lzo-devel'
    ,
      name: 'hadoop-lzo'
    ,
      name: 'hadoop-lzo-native'
    ], (err, serviced) ->
      return next err if err
      modified = true if serviced
      do_core()
  do_core = ->
    ctx.log 'Configure core-site.xml'
    core = {}
    core['io.compression.codecs'] ?= "org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.SnappyCodec"
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/core-site.xml"
      properties: core
      merge: true
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_snappy()

module.exports.push (ctx, next) ->
  @name 'HDP Core # Kerberos'
  {realm} = ctx.config.krb5_client
  {hadoop_conf_dir} = ctx.config.hdp
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
  # core['hadoop.security.auth_to_local'] ?= """
  #   RULE:[2:$1@$0]([jt]t@.*#{realm})s/.*/mapred/
  #   RULE:[2:$1@$0]([nd]n@.*#{realm})s/.*/hdfs/
  #   DEFAULT
  #   """
  # Forgot where I find this one, but referenced here: http://mail-archives.apache.org/mod_mbox/incubator-ambari-commits/201308.mbox/%3Cc82889130fc54e1e8aeabfeedf99dcb3@git.apache.org%3E
  core['hadoop.security.auth_to_local'] ?= """
  
        RULE:[2:$1@$0]([rn]m@.*)s/.*/yarn/
        RULE:[2:$1@$0](jhs@.*)s/.*/mapred/
        RULE:[2:$1@$0]([nd]n@.*)s/.*/hdfs/
        RULE:[2:$1@$0](hm@.*)s/.*/hbase/
        RULE:[2:$1@$0](rs@.*)s/.*/hbase/
        DEFAULT
    """
  # Allow the superuser hive to impersonate any members of the group users. Required only when installing Hive.
  core['hadoop.proxyuser.hive.groups'] ?= '*'
  # Hostname from where superuser hive can connect. Required 
  # only when installing Hive.
  core['hadoop.proxyuser.hive.hosts'] ?= '*'
  # Allow the superuser oozie to impersonate any members of 
  # the group users. Required only when installing Oozie.
  core['hadoop.proxyuser.oozie.groups'] ?= '*'
  # Hostname from where superuser oozie can connect. Required 
  # only when installing Oozie.
  core['hadoop.proxyuser.oozie.hosts'] ?= '*'
  # Hostname from where superuser hcat can connect. Required 
  # only when installing WebHCat.
  core['hadoop.proxyuser.hcat.hosts'] ?= '*'
  # Hostname from where superuser HTTP can connect.
  core['hadoop.proxyuser.HTTP.groups'] ?= '*'
  # Allow the superuser hcat to impersonate any members of the 
  # group users. Required only when installing WebHCat.
  core['hadoop.proxyuser.hcat.groups'] ?= '*'
  # Hostname from where superuser hcat can connect. This is 
  # required only when installing webhcat on the cluster.
  core['hadoop.proxyuser.hcat.hosts'] ?= '*'
  core['hadoop.proxyuser.hue.groups'] ?= '*'
  core['hadoop.proxyuser.hue.hosts'] ?= '*'

  ctx.hconfigure
    destination: "#{hadoop_conf_dir}/core-site.xml"
    properties: core
    merge: true
  , (err, configured) ->
    next err, if configured then ctx.OK else ctx.PASS
  # properties.read ctx.ssh, '/etc/hadoop/conf/core-site.xml', (err, kv) ->
  #   return next err if err
  #   hosts = ctx.config.servers.map( (server) -> server.host ).join(',')
  #   core = {}
  #   # Set the authentication for the cluster. Valid values are: simple or kerberos
  #   core['hadoop.security.authentication'] ?= 'kerberos'
  #   # This is an [OPTIONAL] setting. If not set, defaults to 
  #   # authentication.authentication= authentication only; the client and server 
  #   # mutually authenticate during connection setup.integrity = authentication 
  #   # and integrity; guarantees the integrity of data exchanged between client 
  #   # and server aswell as authentication.privacy = authentication, integrity, 
  #   # and confidentiality; guarantees that data exchanged between client andserver 
  #   # is encrypted and is not readable by a “man in the middle”.
  #   core['hadoop.rpc.protection'] ?= 'authentication'
  #   # Enable authorization for different protocols.
  #   core['hadoop.security.authorization'] ?= 'true'
  #   # The mapping from Kerberos principal names to local OS user names.
  #   # core['hadoop.security.auth_to_local'] ?= """
  #   #   RULE:[2:$1@$0]([jt]t@.*#{realm})s/.*/mapred/
  #   #   RULE:[2:$1@$0]([nd]n@.*#{realm})s/.*/hdfs/
  #   #   DEFAULT
  #   #   """
  #   # Forgot where I find this one, but referenced here: http://mail-archives.apache.org/mod_mbox/incubator-ambari-commits/201308.mbox/%3Cc82889130fc54e1e8aeabfeedf99dcb3@git.apache.org%3E
  #   core['hadoop.security.auth_to_local'] ?= """
    
  #         RULE:[2:$1@$0]([rn]m@.*)s/.*/yarn/
  #         RULE:[2:$1@$0](jhs@.*)s/.*/mapred/
  #         RULE:[2:$1@$0]([nd]n@.*)s/.*/hdfs/
  #         RULE:[2:$1@$0](hm@.*)s/.*/hbase/
  #         RULE:[2:$1@$0](rs@.*)s/.*/hbase/
  #         DEFAULT
  #     """
  #   # Allow the superuser hive to impersonate any members of the group users. Required only when installing Hive.
  #   core['hadoop.proxyuser.hive.groups'] ?= '*'
  #   # Hostname from where superuser hive can connect. Required 
  #   # only when installing Hive.
  #   # core['hadoop.proxyuser.hive.hosts'] ?= hosts
  #   core['hadoop.proxyuser.hive.hosts'] ?= '*'
  #   # Allow the superuser oozie to impersonate any members of 
  #   # the group users. Required only when installing Oozie.
  #   core['hadoop.proxyuser.oozie.groups'] ?= '*'
  #   # Hostname from where superuser oozie can connect. Required 
  #   # only when installing Oozie.
  #   # core['hadoop.proxyuser.oozie.hosts'] ?= hosts
  #   core['hadoop.proxyuser.oozie.hosts'] ?= '*'
  #   # Hostname from where superuser hcat can connect. Required 
  #   # only when installing WebHCat.
  #   # core['hadoop.proxyuser.hcat.hosts'] ?= hosts
  #   core['hadoop.proxyuser.hcat.hosts'] ?= '*'
  #   # Hostname from where superuser HTTP can connect.
  #   core['hadoop.proxyuser.HTTP.groups'] ?= '*'
  #   # Allow the superuser hcat to impersonate any members of the 
  #   # group users. Required only when installing WebHCat.
  #   core['hadoop.proxyuser.hcat.groups'] ?= '*'
  #   # Hostname from where superuser hcat can connect. This is 
  #   # required only when installing webhcat on the cluster.
  #   # core['hadoop.proxyuser.hcat.hosts'] ?= hosts
  #   core['hadoop.proxyuser.hcat.hosts'] ?= '*'
  #   modified = false
  #   for k, v of core
  #     modified = true if kv[k] isnt v
  #     kv[k] = v
  #   return next null, ctx.PASS unless modified
  #   properties.write ctx.ssh, '/etc/hadoop/conf/core-site.xml', kv, (err) ->
  #     next err, ctx.OK
  #     # ctx.service
  #     #   name: 
  #     # On all secure DataNodes, you must set the user to run the DataNode as after dropping privileges.
  #     # export HADOOP_SECURE_DN_USER=$HDFS_USER
  #     # Optionally, you can allow that user to access the directories where PID and log files are stored. For example:
  #     # export HADOOP_SECURE_DN_PID_DIR=/var/run/hadoop/$HADOOP_SECURE_DN_USER
  #     # export HADOOP_SECURE_DN_LOG_DIR=/var/run/hadoop/$HADOOP_SECURE_DN_USER

###
Configure Web
-------------

This action follow the ["Authentication for Hadoop HTTP web-consoles" 
recommandations](http://hadoop.apache.org/docs/r1.2.1/HttpAuthentication.html).
###
module.exports.push (ctx, next) ->
  @name 'HDP Core # Kerberos Web UI'
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
        # For some reason, _HOST isnt leveraged
        'hadoop.http.authentication.kerberos.principal': "HTTP/#{ctx.config.host}@#{realm}"
        'hadoop.http.authentication.kerberos.keytab': '/etc/security/keytabs/spnego.service.keytab'
      merge: true
    , (err, configured) ->
      next err, if configured then ctx.OK else ctx.PASS


    










