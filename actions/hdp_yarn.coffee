
url = require 'url'
misc = require 'mecano/lib/misc'
mkcmd = require './hdp/mkcmd'

module.exports = []

module.exports.push 'histi/actions/hdp_core'

module.exports.push module.exports.configure = (ctx) ->
  require('./hdp_hdfs').configure ctx
  # Grab the host(s) for each roles
  resourcemanager = (ctx.config.servers.filter (s) -> s.hdp?.resourcemanager)[0].host
  ctx.log "Resource manager: #{resourcemanager}"
  jobhistoryserver = (ctx.config.servers.filter (s) -> s.hdp?.jobhistoryserver)[0].host
  ctx.log "Job History Server: #{jobhistoryserver}"
  ctx.config.hdp.yarn_log_dir ?= '/var/log/hadoop-yarn'         # /etc/hadoop/conf/yarn-env.sh#20
  ctx.config.hdp.yarn_pid_dir ?= '/var/run/hadoop-yarn'         # /etc/hadoop/conf/yarn-env.sh#21
  # Define Users and Groups
  ctx.config.hdp.yarn_user ?= 'yarn'
  # Configure yarn
  # Comma separated list of paths. Use the list of directories from $YARN_LOCAL_DIR, eg: /grid/hadoop/hdfs/yarn/local,/grid1/hadoop/hdfs/yarn/local.
  throw new Error 'Required property: hdp.yarn[yarn.nodemanager.local-dirs]' unless ctx.config.hdp.yarn['yarn.nodemanager.local-dirs']
  # Use the list of directories from $YARN_LOCAL_LOG_DIR, eg: /grid/hadoop/yarn/logs /grid1/hadoop/yarn/logs /grid2/hadoop/yarn/logs
  throw new Error 'Required property: hdp.yarn[yarn.nodemanager.log-dirs]' unless ctx.config.hdp.yarn['yarn.nodemanager.log-dirs']
  ctx.config.hdp.yarn['yarn.resourcemanager.resource-tracker.address'] ?= "#{resourcemanager}:8025" # Enter your ResourceManager hostname.
  ctx.config.hdp.yarn['yarn.resourcemanager.scheduler.address'] ?= "#{resourcemanager}:8030" # Enter your ResourceManager hostname.
  ctx.config.hdp.yarn['yarn.resourcemanager.address'] ?= "#{resourcemanager}:8050" # Enter your ResourceManager hostname.
  ctx.config.hdp.yarn['yarn.resourcemanager.admin.address'] ?= "#{resourcemanager}:8041" # Enter your ResourceManager hostname.
  ctx.config.hdp.yarn['yarn.nodemanager.remote-app-log-dir'] ?= "/logs"
  ctx.config.hdp.yarn['yarn.log.server.url'] ?= "http://#{jobhistoryserver}:19888/jobhistory/logs/" # URL for job history server
  ctx.config.hdp.yarn['yarn.resourcemanager.webapp.address'] ?= "#{resourcemanager}:8088" # URL for job history server
  ctx.config.hdp.yarn['yarn.nodemanager.container-executor.class'] ?= 'org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor'
  ctx.config.hdp.yarn['yarn.nodemanager.linux-container-executor.group'] ?= 'yarn'
  # Configurations for History Server (Needs to be moved elsewhere):
  ctx.config.hdp.yarn['yarn.log-aggregation.retain-seconds'] ?= '-1' #  How long to keep aggregation logs before deleting them. -1 disables. Be careful, set this too small and you will spam the name node.
  ctx.config.hdp.yarn['yarn.log-aggregation.retain-check-interval-seconds'] ?= '-1' # Time between checks for aggregated log retention. If set to 0 or a negative value then the value is computed as one-tenth of the aggregated log retention time. Be careful, set this too small and you will spam the name node.
  # [Container Executor](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Configuration_in_Secure_Mode)
  ctx.config.hdp.container_executor ?= {}
  ctx.config.hdp.container_executor['yarn.nodemanager.local-dirs'] ?= ctx.config.hdp.yarn['yarn.nodemanager.local-dirs']
  ctx.config.hdp.container_executor['yarn.nodemanager.linux-container-executor.group'] ?= ctx.config.hdp.yarn['yarn.nodemanager.linux-container-executor.group']
  ctx.config.hdp.container_executor['yarn.nodemanager.log-dirs'] = ctx.config.hdp.yarn['yarn.nodemanager.log-dirs']
  ctx.config.hdp.container_executor['banned.users'] ?= 'hfds,yarn,mapred,bin'
  ctx.config.hdp.container_executor['min.user.id'] ?= '0'

#http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-9.html
#http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode
module.exports.push (ctx, next) ->
  @name "HDP Hadoop YARN # Users & Groups"
  return next() unless ctx.config.hdp.resourcemanager or ctx.config.hdp.nodemanager
  {hadoop_group} = ctx.config.hdp
  ctx.execute
    cmd: "useradd yarn -r -M -g #{hadoop_group} -s /bin/bash -c \"Used by Hadoop YARN service\""
    code: 0
    code_skipped: 9
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP Hadoop YARN # Install Common"
  @timeout -1
  ctx.service [
    name: 'hadoop'
  ,
    name: 'hadoop-yarn'
  ,
    name: 'hadoop-client'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP Hadoop YARN # Directories"
  @timeout -1
  { yarn_user,
    yarn, yarn_log_dir, yarn_pid_dir,
    hadoop_group } = ctx.config.hdp
  modified = false
  do_yarn_log_dirs = -> # not the tranditionnal log dir
    ctx.log "Create yarn dirs: #{yarn['yarn.nodemanager.log-dirs'].join ','}"
    ctx.mkdir
      destination: yarn['yarn.nodemanager.log-dirs']
      uid: yarn_user
      gid: hadoop_group
      mode: 0o0755
    , (err, created) ->
      return next err if err
      modified = true if created
      do_yarn_local_log()
  do_yarn_local_log = ->
    ctx.log "Create yarn dirs: #{yarn['yarn.nodemanager.local-dirs'].join ','}"
    ctx.mkdir
      destination: yarn['yarn.nodemanager.local-dirs']
      uid: yarn_user
      gid: hadoop_group
      mode: 0o0755
    , (err, created) ->
      return next err if err
      modified = true if created
      do_log()
  do_log = ->
    ctx.log "Create hdfs and mapred log: #{yarn_log_dir}"
    ctx.mkdir
      destination: "#{yarn_log_dir}/#{yarn_user}"
      uid: yarn_user
      gid: hadoop_group
      mode: 0o0755
    , (err, created) ->
      return next err if err
      modified = true if created
      do_pid()
  do_pid = ->
    ctx.log "Create pid: #{yarn_pid_dir}"
    ctx.mkdir
      destination: "#{yarn_pid_dir}/#{yarn_user}"
      uid: yarn_user
      gid: hadoop_group
      mode: 0o0755
    , (err, created) ->
      return next err if err
      modified = true if created
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_yarn_log_dirs()

module.exports.push (ctx, next) ->
  @name "HDP Hadoop YARN # Yarn OPTS"
  {yarn_user, hadoop_group, hadoop_conf_dir} = ctx.config.hdp
  ctx.render
    source: "#{__dirname}/hdp/core_hadoop/yarn-env.sh"
    destination: "#{hadoop_conf_dir}/yarn-env.sh"
    context: ctx
    local_source: true
    uid: yarn_user
    gid: hadoop_group
    mode: 0o0755
  , (err, rendered) ->
    next err, if rendered then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP Hadoop YARN # Container Executor"
  modified = false
  mode = 0o6050
  user = 'root'
  group = 'yarn'
  {yarn_user, container_executor, hadoop_conf_dir} = ctx.config.hdp
  container_executor = misc.merge {}, container_executor
  container_executor['yarn.nodemanager.local-dirs'] = container_executor['yarn.nodemanager.local-dirs'].join ','
  container_executor['yarn.nodemanager.log-dirs'] = container_executor['yarn.nodemanager.log-dirs'].join ','
  do_stat = ->
    ce = '/usr/lib/hadoop-yarn/bin/container-executor';
    ctx.log "change ownerships and permissions to '#{ce}'"
    ctx.chown
      destination: ce
      uid: user
      gid: group
    , (err, chowned) ->
      return next err if err
      modified = true if chowned
      ctx.chmod
        destination: ce
        mode: mode
      , (err, chmoded) ->
        return next err if err
        modified = true if chmoded
        do_conf()
  do_conf = ->
    ctx.log "Write to '#{hadoop_conf_dir}/container-executor.cfg' as ini"
    ctx.ini
      destination: "#{hadoop_conf_dir}/container-executor.cfg"
      content: container_executor
      uid: user
      gid: group
      mode: 0o0640
      separator: '='
      backup: true
    , (err, inied) ->
      modified = true if inied
      next err, if modified then ctx.OK else ctx.PASS
  do_stat()

module.exports.push (ctx, next) ->
  @name "HDP Hadoop YARN # Hadoop Configuration"
  { yarn, hadoop_conf_dir, capacity_scheduler } = ctx.config.hdp
  modified = false
  do_yarn = ->
    ctx.log 'Configure yarn-site.xml'
    config = {}
    for k,v of yarn then config[k] = v 
    config['yarn.nodemanager.local-dirs'] = config['yarn.nodemanager.local-dirs'].join ',' if Array.isArray yarn['yarn.nodemanager.local-dirs']
    config['yarn.nodemanager.log-dirs'] = config['yarn.nodemanager.log-dirs'].join ',' if Array.isArray yarn['yarn.nodemanager.log-dirs']
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/yarn-site.xml"
      default: "#{__dirname}/hdp/core_hadoop/yarn-site.xml"
      local_default: true
      properties: config
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_capacity_scheduler()
  do_capacity_scheduler = ->
    ctx.log 'Configure capacity-scheduler.xml'
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/capacity-scheduler.xml"
      default: "#{__dirname}/hdp/core_hadoop/capacity-scheduler.xml"
      local_default: true
      properties: capacity_scheduler
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_yarn()

module.exports.push (ctx, next) ->
  @name 'HDP Hadoop YARN # Kerberos Principals'
  @timeout -1
  {hdfs_user} = ctx.config.hdp
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  ctx.mkdir
    destination: '/etc/security/keytabs'
    uid: 'root'
    gid: 'hadoop'
    mode: '0750'
  , (err, created) ->
    ctx.log 'Creating Service Principals'
    principals = []
    if ctx.config.hdp.resourcemanager
      principals.push
        principal: "rm/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/rm.service.keytab"
        uid: 'yarn'
        gid: 'hadoop'
    if ctx.config.hdp.nodemanager
      principals.push
        principal: "nm/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/nm.service.keytab"
        uid: 'yarn'
        gid: 'hadoop'
    if ctx.config.hdp.jobhistoryserver
      principals.push
        principal: "jhs/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/jhs.service.keytab"
        uid: 'mapred'
        gid: 'hadoop'
    for principal in principals
        principal.kadmin_principal = kadmin_principal
        principal.kadmin_password = kadmin_password
        principal.kadmin_server = kadmin_server
    ctx.krb5_addprinc principals, (err, created) ->
      return next err if err
      next null, if created then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Hadoop YARN # Configure Kerberos'
  {realm} = ctx.config.krb5_client
  {hadoop_conf_dir} = ctx.config.hdp
  yarn = {}
  # Todo: might need to configure WebAppProxy but I understood that it is run as part of rm if not configured separately
  # yarn.web-proxy.address    WebAppProxy                                   host:port for proxy to AM web apps. host:port if this is the same as yarn.resourcemanager.webapp.address or it is not defined then the ResourceManager will run the proxy otherwise a standalone proxy server will need to be launched.
  # yarn.web-proxy.keytab     /etc/security/keytabs/web-app.service.keytab  Kerberos keytab file for the WebAppProxy.
  # yarn.web-proxy.principal  wap/_HOST@REALM.TLD                           Kerberos principal name for the WebAppProxy.
  # Todo: need to deploy "container-executor.cfg"
  # see http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode
  # Configurations the ResourceManager
  yarn['yarn.resourcemanager.keytab'] ?= '/etc/security/keytabs/rm.service.keytab'
  yarn['yarn.resourcemanager.principal'] ?= "rm/_HOST@#{realm}"
  # Configurations for NodeManager:
  yarn['yarn.nodemanager.keytab'] ?= '/etc/security/keytabs/nm.service.keytab'
  yarn['yarn.nodemanager.principal'] ?= "nm/_HOST@#{realm}"
  ctx.hconfigure
    destination: "#{hadoop_conf_dir}/yarn-site.xml"
    properties: yarn
  , (err, configured) ->
    next err, if configured then ctx.OK else ctx.PASS
  # properties.read ctx.ssh, '/etc/hadoop/conf/yarn-site.xml', (err, kv) ->
  #   return next err if err
  #   yarn = {}
  #   # Todo: might need to configure WebAppProxy but I understood that it is run as part of rm if not configured separately
  #   # yarn.web-proxy.address    WebAppProxy                                   host:port for proxy to AM web apps. host:port if this is the same as yarn.resourcemanager.webapp.address or it is not defined then the ResourceManager will run the proxy otherwise a standalone proxy server will need to be launched.
  #   # yarn.web-proxy.keytab     /etc/security/keytabs/web-app.service.keytab  Kerberos keytab file for the WebAppProxy.
  #   # yarn.web-proxy.principal  wap/_HOST@REALM.TLD                           Kerberos principal name for the WebAppProxy.
  #   # Todo: need to deploy "container-executor.cfg"
  #   # see http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode
  #   # Configurations the ResourceManager
  #   modified = false
  #   for k, v of yarn
  #     modified = true if kv[k] isnt v
  #     kv[k] = v
  #   return next null, ctx.PASS unless modified
  #   properties.write ctx.ssh, '/etc/hadoop/conf/yarn-site.xml', kv, (err) ->
  #     next err, ctx.OK

###
Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)
###
module.exports.push (ctx, next) ->
  {hadoop_group, hdfs_user, yarn, yarn_user, mapred, mapred_user} = ctx.config.hdp
  @name 'HDP Hadoop DN # HDFS layout'
  ok = false
  do_remote_app_log_dir = ->
    # Default value for "yarn.nodemanager.remote-app-log-dir" is "/tmp/logs"
    remote_app_log_dir = yarn['yarn.nodemanager.remote-app-log-dir']
    ctx.log "Create #{remote_app_log_dir}"
    ctx.execute
      cmd: mkcmd.hdfs ctx, """
      if hadoop fs -test -d #{remote_app_log_dir}; then exit 1; fi
      hadoop fs -mkdir -p #{remote_app_log_dir}
      hadoop fs -chown #{yarn_user}:#{hadoop_group} #{remote_app_log_dir}
      hadoop fs -chmod 777 #{remote_app_log_dir}
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      ok = true if executed
      do_end()
  do_end = ->
    next null, if ok then ctx.OK else ctx.PASS
  do_remote_app_log_dir()











