
lifecycle = require './lib/lifecycle'
mkcmd = require './lib/mkcmd'
each = require 'each'
exec = require 'superexec'
misc = require 'mecano/lib/misc'
module.exports = []

module.exports.push 'histi/hdp/hdfs'
module.exports.push 'histi/actions/nc'

module.exports.push (ctx) ->
  require('./hdfs').configure ctx
  require('../actions/nc').configure ctx

module.exports.push name: 'HDP HDFS NN # Kerberos', callback: (ctx, next) ->
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  ctx.krb5_addprinc 
    principal: "nn/#{ctx.config.host}@#{realm}"
    randkey: true
    keytab: "/etc/security/keytabs/nn.service.keytab"
    uid: 'hdfs'
    gid: 'hadoop'
    kadmin_principal: kadmin_principal
    kadmin_password: kadmin_password
    kadmin_server: kadmin_server
  , (err, created) ->
    next err, if created then ctx.OK else ctx.PASS

module.exports.push name: 'HDP HDFS NN # HDFS User', callback: (ctx, next) ->
  {hdfs_user, hdfs_password} = ctx.config.hdp
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  ctx.krb5_addprinc
    principal: "#{hdfs_user}@#{realm}"
    password: hdfs_password
    # randkey: true
    # keytab: "/etc/security/keytabs/hdfs.headless.keytab"
    # uid: 'hdfs'
    # gid: 'hadoop'
    # mode: '600'
    kadmin_principal: kadmin_principal
    kadmin_password: kadmin_password
    kadmin_server: kadmin_server
  , (err, created) ->
    next err, if created then ctx.OK else ctx.PASS

module.exports.push name: 'HDP HDFS NN # Format', callback: (ctx, next) ->
  {dfs_name_dir, hdfs_user, format, cluster_name} = ctx.config.hdp
  return next() unless format
  # Shall only be executed on the leader namenode
  namenodes = ctx.hosts_with_module 'histi/hdp/hdfs_nn'
  return next null, ctx.INAPPLICABLE if ctx.config.host isnt namenodes[0]
  ctx.log "Format HDFS if #{dfs_name_dir[0]} does not exist"
  ctx.execute
    #  su -l hdfs -c "hdfs namenode -format duzy"
    # cmd: "yes 'Y' | su -l #{hdfs_user} -c \"/usr/lib/hadoop/bin/hadoop namenode -format\""
    cmd: "su -l #{hdfs_user} -c \"hdfs namenode -format #{cluster_name}\""
    # not_if_exists: "#{dfs_name_dir[0]}/current/fsimage"
    not_if_exists: "#{dfs_name_dir[0]}/current/VERSION"
  , (err, executed) ->
    return next err if err
    return next null, if executed then ctx.OK else ctx.PASS
    lifecycle.nn_start ctx, (err, started) ->
      return next err if err
      lifecycle.dn_start ctx, (err, started) ->
        next err, ctx.OK

module.exports.push name: 'HDP HDFS NN # Upgrade', timeout: -1, callback: (ctx, next) ->
  # Shall only be executed on the leader namenode
  namenodes = ctx.hosts_with_module 'histi/hdp/hdfs_nn'
  return next null, ctx.INAPPLICABLE if ctx.config.host isnt namenodes[0]
  {hdfs_log_dir} = ctx.config.hdp
  count = (callback) ->
    ctx.execute
      cmd: "cat #{hdfs_log_dir}/*/*.log | grep 'upgrade to version' | wc -l"
    , (err, executed, stdout) ->
      callback err, parseInt(stdout.trim(), 10) or 0
  ctx.log 'Dont try to upgrade if namenode is running'
  lifecycle.nn_status ctx, (err, started) ->
    return next err if err
    return next null, ctx.DISABLED if started
    ctx.log 'Count how many upgrade msg in log'
    count (err, c1) ->
      return next err if err
      ctx.log 'Start namenode'
      lifecycle.nn_start ctx, (err, started) ->
        return next err if err
        return next null, ctx.PASS if started
        ctx.log 'Count again'
        count (err, c2) ->
          return next err if err
          return next null, ctx.PASS if c1 is c2
          return next new Error 'Upgrade manually'

module.exports.push name: 'HDP HDFS NN # HA', callback: (ctx, next) ->
  {hadoop_conf_dir} = ctx.config.hdp
  modified = false
  namenodes = ctx.hosts_with_module 'histi/hdp/hdfs_nn'
  journalnodes = ctx.hosts_with_module 'histi/hdp/hdfs_jn'
  nameservice = 'hadooper'
  hdfs_site = {}
  hdfs_site['dfs.nameservices'] = nameservice
  hdfs_site["dfs.ha.namenodes.#{nameservice}"] = (for nn in namenodes then nn.split('.')[0]).join ','
  for nn in namenodes
    hdfs_site["dfs.namenode.rpc-address.#{nameservice}.#{nn.split('.')[0]}"] = "#{nn}:8020"
    hdfs_site["dfs.namenode.http-address.#{nameservice}.#{nn.split('.')[0]}"] = "#{nn}:50070"
  hdfs_site['dfs.namenode.shared.edits.dir'] = (for jn in journalnodes then "#{jn}:8485").join ';'
  hdfs_site['dfs.namenode.shared.edits.dir'] = "qjournal://#{hdfs_site['dfs.namenode.shared.edits.dir']}/#{nameservice}"
  hdfs_site["dfs.client.failover.proxy.provider.#{nameservice}"] = 'org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider'
  hdfs_site['dfs.ha.fencing.methods'] = 'sshfence'
  hdfs_site['dfs.ha.fencing.ssh.private-key-files'] = '/root/.ssh/id_rsa'
  ctx.hconfigure
    destination: "#{hadoop_conf_dir}/hdfs-site.xml"
    properties: hdfs_site
    merge: true
  , (err, configured) ->
    next err, if configured then ctx.OK else ctx.PASS

module.exports.push name: 'HDP HDFS NN # HA Init JournalNodes', timeout: -1, callback: (ctx, next) ->
  # Shall only be executed on the main namenode
  namenodes = ctx.hosts_with_module 'histi/hdp/hdfs_nn'
  journalnodes = ctx.hosts_with_module 'histi/hdp/hdfs_jn'
  return next null, ctx.INAPPLICABLE if ctx.config.host isnt namenodes[0]
  # count_stop = 0
  do_wait = ->
    # all the JournalNodes shall be started
    options = ctx.config.servers
      .filter( (server) -> journalnodes.indexOf(server.host) isnt -1 )
      .map( (server) -> host: server.host, port: 8485 )
    ctx.waitForConnection options, (err) ->
      return next err if err
      do_init()
  do_init = ->
    exists = 0
    each(journalnodes)
    .on 'item', (journalnode, next) ->
      ctx.connect journalnode, (err, ssh) ->
        return next err if err
        dir = "#{ctx.config.hdp.hdfs_site['dfs.journalnode.edits.dir']}/hadooper"
        misc.file.exists ssh, dir, (err, exist) ->
          exists++ if exist
          next()
    .on 'error', (err) ->
      next err
    .on 'end', ->
      return next null, ctx.PASS if exists is journalnodes.length
      return next null, ctx.TODO if exists > 0 and exists < journalnodes.length
      lifecycle.nn_stop ctx, (err, stoped) ->
        return next err if err
        ctx.execute
          cmd: "su -l hdfs -c \"hdfs namenode -initializeSharedEdits -nonInteractive\""
          # code_skipped: 1
        , (err, executed, stdout) ->
          return next err if err
          next null, ctx.OK
  do_wait()

module.exports.push name: 'HDP HDFS NN # HA Init NameNodes', timeout: -1, callback: (ctx, next) ->
  # Shall only be executed on the main namenode
  namenodes = ctx.hosts_with_module 'histi/hdp/hdfs_nn'
  return next null, ctx.INAPPLICABLE if ctx.config.host is namenodes[0]
  again = true
  do_wait = ->
    ctx.waitForConnection namenodes[0], 8020, (err) ->
      return next err if err
      do_init()
  do_init = ->
    ctx.execute
      cmd: "su -l hdfs -c \"hdfs namenode -bootstrapStandby -nonInteractive\""
      # code_skipped: if again then null else 1
      code_skipped: 5
    , (err, executed, stdout) ->
      return next err if err
      next null, if executed then ctx.OK else ctx.PASS
  do_wait()

# module.exports.push name: 'HDP HDFS NN # HA Service State', timeout: -1, callback: (ctx, next) ->
#   # Shall only be executed on the main namenode
#   namenodes = ctx.hosts_with_module 'histi/hdp/hdfs_nn'
#   return next null, ctx.INAPPLICABLE if ctx.config.host isnt namenodes[0]
#   ctx.execute
#     cmd: "hdfs haadmin -failover --forcefence --forceactive hadooper #{ctx.config.host.split('.')[0]}"
#   , (err, executed, stdout) ->
#     return next err if err
#     next null, if executed then ctx.OK else ctx.PASS

module.exports.push name: 'HDP HDFS NN # HA Auto Failover', timeout: -1, callback: (ctx, next) ->
  {hadoop_conf_dir} = ctx.config.hdp
  zookeepers = ctx.hosts_with_module 'histi/hdp/zookeeper'
  modified = false
  do_hdfs = ->
    ctx.log "Enable automatic failover in hdfs-site"
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/hdfs-site.xml"
      properties: 'dfs.ha.automatic-failover.enabled': 'true'
      merge: true
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_core()
  do_core = ->
    ctx.log "Configure ha zookeeper quorum in core-site"
    quorum = ctx.config.servers
      .filter( (server) -> zookeepers.indexOf(server.host) isnt -1 )
      .map( (server) -> "#{server.host}:2181" )
      .join ','
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/core-site.xml"
      properties: 'ha.zookeeper.quorum': quorum
      merge: true
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_wait()
  do_wait = ->
    ctx.log "Make sure all instances of zookeeper are available"
    ctx.waitForConnection zookeepers, 2181, (err) ->
      return next err if err
      do_zkfc()
  do_zkfc = ->
    do_zkfc_active()
  do_zkfc_active = ->
    ctx.log "Format zookeeper"
    ctx.execute
      cmd: 'yes | hdfs zkfc -formatZK'
    , (err, executed) ->
      next null, if modified then ctx.OK else ctx.PASS
  do_hdfs()

module.exports.push name: 'HDP HDFS NN # Start', timeout: -1, callback: (ctx, next) ->
  do_wait = ->
    jns = ctx.hosts_with_module 'histi/hdp/hdfs_jn'
    # Check if we are HA
    return do_start() if jns.length is 0
    # If so, at least one journalnode must be available
    done = false
    e = each(jns)
    .parallel(true)
    .on 'item', (jn, next) ->
      ctx.waitForConnection jn, 8485, (err) ->
        return if done
        done = true
        e.close() # No item will be emitted after this call
        do_start()
    .on 'error', next
  do_start = ->
    lifecycle.nn_start ctx, (err, started) ->
      next err, if started then ctx.OK else ctx.PASS
  do_wait()

module.exports.push name: 'HDP HDFS NN # Test User', timeout: -1, callback: (ctx, next) ->
  {hdfs_user, test_user, test_password, hadoop_group, security} = ctx.config.hdp
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  modified = false
  do_user = ->
    if security is 'kerberos'
    then do_user_krb5()
    else do_user_unix()
  do_user_unix = ->
    ctx.execute
      cmd: "useradd #{test_user} -r -M -g #{hadoop_group} -s /bin/bash -c \"Used by Hadoop to test\""
      code: 0
      code_skipped: 9
    , (err, created) ->
      return next err if err
      modified = true if created
      do_run()
  do_user_krb5 = ->
    ctx.krb5_addprinc
      principal: "#{test_user}@#{realm}"
      password: "#{test_password}"
      # randkey: true
      # keytab: "/etc/security/keytabs/test.headless.keytab"
      kadmin_principal: kadmin_principal
      kadmin_password: kadmin_password
      kadmin_server: kadmin_server
    , (err, created) ->
      return next err if err
      modified = true if created
      do_run()
  do_run = ->
    ctx.execute
      cmd: mkcmd.hdfs ctx, """
      if hdfs dfs -ls /user/test 2>/dev/null; then exit 1; fi
      hdfs dfs -mkdir /user/test
      hdfs dfs -chown test /user/test
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      modified = true if executed
      next err, if modified then ctx.OK else ctx.PASS
  do_user()




