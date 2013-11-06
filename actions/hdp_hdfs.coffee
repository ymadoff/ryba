
url = require 'url'

module.exports = []
module.exports.push 'histi/actions/yum'
module.exports.push 'histi/actions/krb5_client' #kadmin must be present
module.exports.push 'histi/actions/hdp_core'

###
Note about upgrade from 1.3.x to 2.x, once we install 
the new repo, yum update failed. We should first remove 
some package, here's how: `yum remove hadoop-native hadoop-pipes hadoop-sbin`.
###
module.exports.push module.exports.configure = (ctx) ->
  require('./hdp_core').configure ctx
  require('./krb5_client').configure ctx
  # hadoop env
  ctx.config.hdp.hadoop_opts ?= 'java.net.preferIPv4Stack': true
  hadoop_opts = "export HADOOP_OPTS=\""
  for k, v of ctx.config.hdp.hadoop_opts
    hadoop_opts += "-D#{k}=#{v} "
  hadoop_opts += "${HADOOP_OPTS}\""
  ctx.config.hdp.cluster_name ?= ''
  ctx.config.hdp.hadoop_opts = hadoop_opts
  # Define Directories for Core Hadoop
  ctx.config.hdp.dfs_name_dir ?= ['/hadoop/hdfs/namenode']
  ctx.config.hdp.dfs_data_dir ?= ['/hadoop/hdfs/data']
  ctx.config.hdp.hdfs_log_dir ?= '/var/log/hadoop-hdfs'
  ctx.config.hdp.mapred_log_dir ?= '/var/log/hadoop-mapreduce' # required by hadoop-env.sh
  ctx.config.hdp.hdfs_pid_dir ?= '/var/run/hadoop-hdfs'
  ctx.config.hdp.hdfs_user ?= 'hdfs'
  ctx.config.hdp.fs_checkpoint_dir ?= ['/hadoop/hdfs/snn'] # Default ${fs.checkpoint.dir}
  # Options and configuration
  ctx.config.hdp.nn_port ?= '50070'
  ctx.config.hdp.snn_port ?= '50090'
  # Options for hdfs-site.xml
  ctx.config.hdp.hdfs ?= {}
  ctx.config.hdp.hdfs['dfs.datanode.data.dir.perm'] ?= '750'
  # Options for hadoop-env.sh
  ctx.config.hdp.options ?= {}
  ctx.config.hdp.options['java.net.preferIPv4Stack'] ?= true
  ctx.config.hdp.hadoop_policy ?= {}

#http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-9.html
#http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode
module.exports.push (ctx, next) ->
  @name "HDP Hadoop HDFS # Users"
  return next() unless ctx.config.hdp.namenode or ctx.config.hdp.secondary_namenode or ctx.config.hdp.datanode
  {hadoop_group} = ctx.config.hdp
  ctx.execute
    cmd: "useradd hdfs -c \"Used by Hadoop HDFS service\" -r -M -g #{hadoop_group}"
    code: 0
    code_skipped: 9
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP Hadoop HDFS # Install"
  @timeout -1
  ctx.service [
    name: 'hadoop'
  ,
    name: 'hadoop-hdfs'
  ,
    name: 'hadoop-libhdfs'
  ,
    name: 'hadoop-client'
  ,
    name: 'openssl'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP Hadoop HDFS # Directories"
  @timeout -1
  { dfs_name_dir, dfs_data_dir, yarn_user, mapred_user,
    fs_checkpoint_dir,
    yarn, yarn_log_dir, yarn_pid_dir,
    hdfs_user, hadoop_group,
    hdfs_log_dir, mapred_log_dir, hdfs_pid_dir, mapred_pid_dir} = ctx.config.hdp
  modified = false
  do_namenode = ->
    ctx.log "Create namenode dir: #{dfs_name_dir}"
    ctx.mkdir
      destination: dfs_name_dir
      uid: hdfs_user
      gid: hadoop_group
      mode: 0o755
    , (err, created) ->
      return next err if err
      modified = true if created
      do_secondarynamenode()
  do_secondarynamenode = ->
    ctx.log "Create secondarynamenode dir: #{dfs_name_dir}"
    ctx.mkdir
      destination: dfs_name_dir
      uid: hdfs_user
      gid: hadoop_group
      mode: 0o755
    , (err, created) ->
      return next err if err
      modified = true if created
      do_datanode()
  do_datanode = ->
    ctx.log "Create datanode dir: #{dfs_data_dir}"
    ctx.mkdir
      destination: dfs_data_dir
      uid: hdfs_user
      gid: hadoop_group
      mode: 0o750
    , (err, created) ->
      return next err if err
      modified = true if created
      do_checkpoint()
  do_checkpoint = ->
    ctx.log "Create checkpoint dir: #{fs_checkpoint_dir}"
    ctx.mkdir
      destination: fs_checkpoint_dir
      uid: hdfs_user
      gid: hadoop_group
      mode: 0o755
    , (err, created) ->
      return next err if err
      modified = true if created
      do_log()
  do_log = ->
    ctx.log "Create hdfs and mapred log: #{hdfs_log_dir}"
    ctx.mkdir
      destination: "#{yarn_log_dir}/#{yarn_user}"
      uid: yarn_user
      gid: hadoop_group
      mode: 0o755
    , (err, created) ->
      return next err if err
      modified = true if created
      do_pid()
  do_pid = ->
    ctx.log "Create hdfs and mapred pid: #{hdfs_pid_dir}, #{yarn_pid_dir} and #{mapred_pid_dir}"
    ctx.mkdir
      destination: "#{hdfs_pid_dir}/#{hdfs_user}"
      uid: hdfs_user
      gid: hadoop_group
      mode: 0o755
    , (err, created) ->
      return next err if err
      modified = true if created
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_namenode()

module.exports.push (ctx, next) ->
  @name "HDP Hadoop HDFS # Hadoop OPTS"
  {hadoop_conf_dir} = ctx.config.hdp
  # For now, only "hadoop_opts" config property is used
  # Todo: 
  # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.5.0/bk_installing_manually_book/content/rpm_chap3.html
  # Change the value of the -XX:MaxnewSize parameter to 1/8th the value of the maximum heap size (-Xmx) parameter.
  ctx.render
    source: "#{__dirname}/hdp/core_hadoop/hadoop-env.sh"
    destination: "#{hadoop_conf_dir}/hadoop-env.sh"
    context: ctx
    local_source: true
    uid: 'hdfs'
    gid: 'hadoop'
    mode: 0o755
  , (err, rendered) ->
    next err, if rendered then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP Hadoop HDFS # Hadoop Configuration"
  namenode = (ctx.config.servers.filter (s) -> s.hdp?.namenode)[0].host
  ctx.log "Namenode: #{namenode}"
  secondary_namenode = (ctx.config.servers.filter (s) -> s.hdp?.secondary_namenode)[0].host
  ctx.log "Secondary namenode: #{secondary_namenode}"
  jobhistoryserver = (ctx.config.servers.filter (s) -> s.hdp?.jobhistoryserver)[0].host
  # jobtraker = (ctx.config.servers.filter (s) -> s.hdp?.jobtraker)[0].host
  slaves = (ctx.config.servers.filter (s) -> s.hdp?.datanode).map (s) -> s.host
  { core, hdfs, yarn, mapred,
    hadoop_conf_dir, fs_checkpoint_dir, # fs_checkpoint_edit_dir,
    dfs_name_dir, dfs_data_dir, 
    nn_port, snn_port } = ctx.config.hdp #mapreduce_local_dir, 
  modified = false
  do_hdfs = ->
    ctx.log 'Configure hdfs-site.xml'
    # Fix: the "dfs.cluster.administrators" value has a space inside
    hdfs['dfs.cluster.administrators'] = 'hdfs'
    # Comma separated list of paths. Use the list of directories from $DFS_NAME_DIR.  
    # For example, /grid/hadoop/hdfs/nn,/grid1/hadoop/hdfs/nn.
    hdfs['dfs.namenode.name.dir'] ?= dfs_name_dir.join ','
    # Comma separated list of paths. Use the list of directories from $DFS_DATA_DIR.  
    # For example, /grid/hadoop/hdfs/dn,/grid1/hadoop/hdfs/dn.
    hdfs['dfs.datanode.data.dir'] ?= dfs_data_dir.join ','
    # NameNode hostname for http access.
    hdfs['dfs.namenode.http-address'] ?= "#{namenode}:#{nn_port}"
    # Secondary NameNode hostname
    hdfs['dfs.namenode.secondary.http-address'] ?= "hdfs://#{secondary_namenode}:#{snn_port}"
    # NameNode hostname for https access
    hdfs['dfs.https.address'] ?= "hdfs://#{namenode}:50470"
    hdfs['dfs.namenode.checkpoint.dir'] ?= fs_checkpoint_dir.join ','
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/hdfs-site.xml"
      default: "#{__dirname}/hdp/core_hadoop/hdfs-site.xml"
      local_default: true
      properties: hdfs
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_master()
  do_master = ->
    # Accoring to [Yahoo!](http://developer.yahoo.com/hadoop/tutorial/module7.html):
    # The conf/masters file contains the hostname of the
    # SecondaryNameNode. This should be changed from "localhost"
    # to the fully-qualified domain name of the node to run the
    # SecondaryNameNode service. It does not need to contain
    # the hostname of the JobTracker/NameNode machine; 
    # Also some [interesting info about snn](http://blog.cloudera.com/blog/2009/02/multi-host-secondarynamenode-configuration/)
    ctx.log 'Configure masters'
    ctx.write
      content: "#{secondary_namenode}"
      destination: "#{hadoop_conf_dir}/masters"
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_slaves()
  do_slaves = ->
    ctx.log 'Configure slaves'
    ctx.write
      content: "#{slaves.join '\n'}"
      destination: "#{hadoop_conf_dir}/slaves"
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_hdfs()

module.exports.push (ctx, next) ->
  @name 'HDP Hadoop HDFS # Configure HTTPS'
  {hadoop_conf_dir, hadoop_policy} = ctx.config.hdp
  namenode = ctx.config.servers.filter( (server) -> server.hdp?.namenode )[0].host
  modified = false
  do_hdfs_site = ->
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/hdfs-site.xml"
      properties:
        # Decide if HTTPS(SSL) is supported on HDFS
        # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.5.0/bk_reference/content/ch_wire1.html
        # For now (oct 7th, 2013), we disable it because nn and dn doesnt start
        'dfs.https.enable': 'false'
        'dfs.https.namenode.https-address': "#{namenode}:50470"
        # The https port where NameNode binds
        'dfs.https.port': '50470'
        # The https address where namenode binds. Example: ip-10-111-59-170.ec2.internal:50470
        'dfs.https.address': "#{namenode}:50470"
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_hadoop_policy()
  do_hadoop_policy = ->
    ctx.log 'Configure hadoop-policy.xml'
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/hadoop-policy.xml"
      default: "#{__dirname}/hdp/core_hadoop/hadoop-policy.xml"
      local_default: true
      properties: hadoop_policy
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_hdfs_site()

module.exports.push (ctx, next) ->
  @name 'HDP Hadoop HDFS # Kerberos Principals'
  @timeout -1
  {hdfs_user} = ctx.config.hdp
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  ctx.mkdir
    destination: '/etc/security/keytabs'
    uid: 'root'
    gid: 'hadoop'
    mode: 0o750
  , (err, created) ->
    ctx.log 'Creating Service Principals'
    principals = []
    if ctx.config.hdp.namenode or ctx.config.hdp.datanode or ctx.config.hdp.secondary_namenode or ctx.config.hdp.oozie or ctx.config.hdp.webhcat
      principals.push
        principal: "HTTP/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/spnego.service.keytab"
        uid: 'hdfs'
        gid: 'hadoop'
        mode: 0o660 # need rw access for hadoop and mapred users
    for principal in principals
        principal.kadmin_principal = kadmin_principal
        principal.kadmin_password = kadmin_password
        principal.kadmin_server = kadmin_server
    ctx.krb5_addprinc principals, (err, created) ->
      next err, if created then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Hadoop HDFS # Kerberos Configure'
  {realm} = ctx.config.krb5_client
  {hadoop_conf_dir} = ctx.config.hdp
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
  # # Default to ${dfs.web.authentication.kerberos.principal}, but documented in hdp 1.3.2 manual install
  hdfs['dfs.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/_HOST@#{realm}"
  # # Default to ${dfs.web.authentication.kerberos.principal}, but documented in hdp 1.3.2 manual install
  hdfs['dfs.secondary.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/_HOST@#{realm}"
  hdfs['dfs.datanode.data.dir.perm'] ?= '700'
  # The address, with a privileged port - any port number under 1023. Example: 0.0.0.0:1019
  hdfs['dfs.datanode.address'] ?= '0.0.0.0:1019'
  # The address, with a privileged port - any port number under 1023. Example: 0.0.0.0:1022
  # update, [official doc propose port 2005 only for https, http is not even documented](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Configuration_in_Secure_Mode)
  hdfs['dfs.datanode.http.address'] ?= '0.0.0.0:1022'
  hdfs['dfs.datanode.https.address'] ?= '0.0.0.0:1023'
  # Documented in http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode
  # Only seems to apply if "dfs.https.enable" is enabled
  hdfs['dfs.namenode.kerberos.https.principal'] = "host/_HOST@#{realm}"
  hdfs['dfs.secondary.namenode.kerberos.https.principal'] = "host/_HOST@#{realm}"
  ctx.hconfigure
    destination: "#{hadoop_conf_dir}/hdfs-site.xml"
    properties: hdfs
  , (err, configured) ->
    next err, if configured then ctx.OK else ctx.PASS
  # properties.read ctx.ssh, '/etc/hadoop/conf/hdfs-site.xml', (err, kv) ->
  #   return next err if err
  #   namenode = ctx.config.servers.filter( (server) -> server.hdp?.namenode )[0].host
  #   secondary_namenode = ctx.config.servers.filter( (server) -> server.hdp?.secondary_namenode )[0].host
  #   hdfs = {}
  #   # If "true", access tokens are used as capabilities
  #   # for accessing datanodes. If "false", no access tokens are checked on
  #   # accessing datanodes.
  #   hdfs['dfs.block.access.token.enable'] ?= 'true'
  #   # Kerberos principal name for the NameNode
  #   hdfs['dfs.namenode.kerberos.principal'] ?= "nn/_HOST@#{realm}"
  #   # Kerberos principal name for the secondary NameNode.
  #   hdfs['dfs.secondary.namenode.kerberos.principal'] ?= "nn/_HOST@#{realm}"
  #   # Address of secondary namenode web server
  #   hdfs['dfs.secondary.http.address'] ?= "#{secondary_namenode}:50090"
  #   # The https port where secondary-namenode binds
  #   hdfs['dfs.secondary.https.port'] ?= '50490'
  #   # The HTTP Kerberos principal used by Hadoop-Auth in the HTTP 
  #   # endpoint. The HTTP Kerberos principal MUST start with 'HTTP/' 
  #   # per Kerberos HTTP SPNEGO specification. 
  #   hdfs['dfs.web.authentication.kerberos.principal'] ?= "HTTP/_HOST@#{realm}"
  #   # The Kerberos keytab file with the credentials for the HTTP 
  #   # Kerberos principal used by Hadoop-Auth in the HTTP endpoint.
  #   hdfs['dfs.web.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab'
  #   # The Kerberos principal that the DataNode runs as. "_HOST" is replaced by the real host name.  
  #   hdfs['dfs.datanode.kerberos.principal'] ?= "dn/_HOST@#{realm}"
  #   # Combined keytab file containing the NameNode service and host principals.
  #   hdfs['dfs.namenode.keytab.file'] ?= '/etc/security/keytabs/nn.service.keytab'
  #   # Combined keytab file containing the NameNode service and host principals.
  #   hdfs['dfs.secondary.namenode.keytab.file'] ?= '/etc/security/keytabs/nn.service.keytab'
  #   # The filename of the keytab file for the DataNode.
  #   hdfs['dfs.datanode.keytab.file'] ?= '/etc/security/keytabs/dn.service.keytab'
  #   # # Default to ${dfs.web.authentication.kerberos.principal}, but documented in hdp 1.3.2 manual install
  #   hdfs['dfs.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/_HOST@#{realm}"
  #   # # Default to ${dfs.web.authentication.kerberos.principal}, but documented in hdp 1.3.2 manual install
  #   hdfs['dfs.secondary.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/_HOST@#{realm}"
  #   hdfs['dfs.datanode.data.dir.perm'] ?= '700'
  #   # The address, with a privileged port - any port number under 1023. Example: 0.0.0.0:1019
  #   hdfs['dfs.datanode.address'] ?= '0.0.0.0:1019'
  #   # The address, with a privileged port - any port number under 1023. Example: 0.0.0.0:1022
  #   # update, [official doc propose port 2005 only for https, http is not even documented](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Configuration_in_Secure_Mode)
  #   hdfs['dfs.datanode.http.address'] ?= '0.0.0.0:1022'
  #   hdfs['dfs.datanode.https.address'] ?= '0.0.0.0:1023'
  #   # Documented in http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode
  #   # Only seems to apply if "dfs.https.enable" is enabled
  #   hdfs['dfs.namenode.kerberos.https.principal'] = "host/_HOST@#{realm}"
  #   hdfs['dfs.secondary.namenode.kerberos.https.principal'] = "host/_HOST@#{realm}"
  #   modified = false
  #   for k, v of hdfs
  #     modified = true if kv[k] isnt v
  #     kv[k] = v
  #   return next null, ctx.PASS unless modified
  #   properties.write ctx.ssh, '/etc/hadoop/conf/hdfs-site.xml', kv, (err) ->
  #     next err, ctx.OK










