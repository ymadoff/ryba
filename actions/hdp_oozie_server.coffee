
path = require 'path'
lifecycle = require './hdp/lifecycle'

module.exports = []

module.exports.push 'histi/actions/hdp_core'

module.exports.push module.exports.configure = (ctx) ->
  require('./hdp_core').configure ctx
  oozie_server = (ctx.config.servers.filter (s) -> s.hdp?.oozie_server)[0].host
  ctx.config.hdp.oozie_user ?= 'oozie'
  ctx.config.hdp.oozie_conf_dir ?= '/etc/oozie/conf'
  ctx.config.hdp.oozie_data ?= '/var/db/oozie'
  ctx.config.hdp.oozie_log_dir ?= '/var/log/oozie'
  ctx.config.hdp.oozie_pid_dir ?= '/var/run/oozie'
  ctx.config.hdp.oozie_tmp_dir ?= '/var/tmp/oozie'
  ctx.config.hdp.oozie_site ?= {}
  ctx.config.hdp.oozie_site['oozie.base.url'] = "http://#{oozie_server}:11000/oozie"
  # ctx.config.hdp.oozie_site['oozie.service.Store­Service.jdbc.url'] = "jdbc:derby:#{ctx.config.hdp.oozie_data}/oozie;create=true"
  # ctx.config.hdp.oozie_site['oozie.service.JPAService.jdbc.driver']
  # ctx.config.hdp.oozie_site['oozie.service.JPAService.jdbc.username']
  # ctx.config.hdp.oozie_site['oozie.service.JPAService.jdbc.password']
  # TODO: check if security is on
  ctx.config.hdp.oozie_site['oozie.service.AuthorizationService.security.enabled'] = 'true'
  ctx.config.hdp.oozie_site['oozie.service.HadoopAccessorService.kerberos.enabled'] = 'true'
  ctx.config.hdp.oozie_site['local.realm'] = 'ADALTAS.COM'
  ctx.config.hdp.oozie_site['oozie.service.HadoopAccessorService.keytab.file'] = '/etc/security/keytabs/oozie.service.keytab'
  ctx.config.hdp.oozie_site['oozie.service.HadoopAccessorService.kerberos.principal'] = "oozie/#{ctx.config.host}@ADALTAS.COM"
  ctx.config.hdp.oozie_site['oozie.authentication.type'] = 'kerberos'
  ctx.config.hdp.oozie_site['oozie.authentication.kerberos.principal'] = "HTTP/#{ctx.config.host}@ADALTAS.COM"
  ctx.config.hdp.oozie_site['oozie.authentication.kerberos.keytab'] = '/etc/security/keytabs/spnego.service.keytab'
  ctx.config.hdp.oozie_site['oozie.service.HadoopAccessorService.nameNode.whitelist'] = ''
  ctx.config.hdp.oozie_site['oozie.authentication.kerberos.name.rules'] = """
  
      RULE:[2:$1@$0]([rn]m@.*)s/.*/yarn/
      RULE:[2:$1@$0](jhs@.*)s/.*/mapred/
      RULE:[2:$1@$0]([nd]n@.*)s/.*/hdfs/
      RULE:[2:$1@$0](hm@.*)s/.*/hbase/
      RULE:[2:$1@$0](rs@.*)s/.*/hbase/
      DEFAULT
  """
  ctx.config.hdp.oozie_hadoop_config ?= {}
  ctx.config.hdp.oozie_hadoop_config['mapreduce.jobtracker.kerberos.principal'] ?= "mapred/_HOST@ADALTAS.COM"
  ctx.config.hdp.oozie_hadoop_config['yarn.resourcemanager.principal'] ?= "yarn/_HOST@ADALTAS.COM"
  ctx.config.hdp.oozie_hadoop_config['dfs.namenode.kerberos.principal'] ?= "hdfs/_HOST@ADALTAS.COM"
  ctx.config.hdp.oozie_hadoop_config['mapreduce.framework.name'] ?= "yarn"
  ctx.config.hdp.extjs ?= {}
  throw new Error "Missing extjs.source" unless ctx.config.hdp.extjs.source
  throw new Error "Missing extjs.destination" unless ctx.config.hdp.extjs.destination

module.exports.push (ctx, next) ->
  @name 'HDP Oozie # Install'
  @timeout -1
  ctx.service [
    name: 'oozie'
  ,
    name: 'oozie-client'
  ,
    name: 'extjs-2.2-1'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Oozie # Layout'
  ctx.mkdir
    destination: '/usr/lib/oozie/libext'
  , (err, created) ->
    next err, if created then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Oozie # ExtJS'
  ctx.execute
    cmd: 'cp /usr/share/HDP-oozie/ext-2.2.zip /usr/lib/oozie/libext/'
    not_if_exists: '/usr/lib/oozie/libext/ext-2.2.zip'
  , (err, copied) ->
    next err, if copied then ctx.OK else ctx.PASS

# module.exports.push (ctx, next) ->
#   @name 'HDP Oozie # ExtJS'
#   @timeout 2*60*1000
#   {proxy, extjs} = ctx.config.hdp
#   ctx.log "Download extjs to /tmp/#{path.basename extjs.source}"
#   u = url.parse extjs_url
#   ctx[if u.protocol is 'http:' then 'download' else 'upload']
#     source: extjs.source
#     # local_source: true
#     proxy: proxy
#     destination: "/tmp/#{path.basename extjs.source}"
#     not_if_exists: "#{destination}"
#   , (err, downloaded) ->
#     return next err, ctx.PASS if err or not downloaded
#     ctx.log "Unzip /tmp/#{path.basename extjs.source}"
#     ctx.execute
#       cmd: "cd /tmp && unzip /tmp/#{path.basename extjs.source}"
#     , (err, executed) ->
#       return next err if err
#       tempdestination = "/tmp/#{path.basename extjs.source, '.zip'}"
#       ctx.log 'Move to final destination #{destination}'
#       ctx.execute
#         cmd: "rm -rf #{destination} && mv #{tempdestination} #{destination}"
#       , (err, executed) ->
#         next err, ctx.OK

module.exports.push (ctx, next) ->
  @name 'HDP Oozie # LZO'
  ctx.execute
    cmd: 'cp /usr/lib/hadoop/lib/hadoop-lzo-0.5.0.jar /usr/lib/oozie/libext/'
    not_if_exists: '/usr/lib/oozie/libext/hadoop-lzo-0.5.0.jar'
  , (err, copied) ->
    next err, if copied then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {oozie_user, hadoop_group} = ctx.config.hdp
  @name 'HDP Oozie # Users & Groups'
  ctx.execute
    cmd: "useradd oozie -c \"Used by Hadoop Oozie service\" -r -M -g #{hadoop_group}"
    code: 0
    code_skipped: 9
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Oozie # Directories'
  {oozie_user, hadoop_group, oozie_data, oozie_log_dir, oozie_pid_dir, oozie_tmp_dir} = ctx.config.hdp
  ctx.mkdir [
    destination: oozie_data
    uid: oozie_user
    gid: hadoop_group
    mode: 0o0755
  ,
    destination: oozie_log_dir
    uid: oozie_user
    gid: hadoop_group
    mode: 0o0755
  ,
    destination: oozie_pid_dir
    uid: oozie_user
    gid: hadoop_group
    mode: 0o0755
  ,
    destination: oozie_tmp_dir
    uid: oozie_user
    gid: hadoop_group
    mode: 0o0755
  ], (err, copied) ->
    next err, if copied then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP Oozie # Configuration"
  { oozie_user, hadoop_user, hadoop_group, oozie_site, oozie_conf_dir, oozie_hadoop_config, hadoop_conf_dir } = ctx.config.hdp
  modified = false
  do_oozie_site = ->
    ctx.log 'Configure oozie-site.xml'
    ctx.hconfigure
      destination: "#{oozie_conf_dir}/oozie-site.xml"
      default: "#{__dirname}/hdp/oozie/oozie-site.xml"
      local_default: true
      properties: oozie_site
      uid: oozie_user
      guid: hadoop_group
      mode: 0o0755
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_hadoop_config()
  do_hadoop_config = ->
    ctx.log 'Configure hadoop-config.xml'
    ctx.hconfigure
      destination: "#{oozie_conf_dir}/hadoop-config.xml"
      default: "#{__dirname}/hdp/oozie/hadoop-config.xml"
      local_default: true
      properties: oozie_hadoop_config
      uid: oozie_user
      guid: hadoop_group
      mode: 0o0755
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_hadoop_link()
  do_hadoop_link = ->
    ctx.log 'Configure hadoop_conf link'
    ctx.link
      source: "#{hadoop_conf_dir}"
      destination: "#{oozie_conf_dir}/hadoop-conf"
      uid: hadoop_user
      guid: hadoop_group
    , (err, linked) ->
      return next err if err
      modified = true if linked
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_oozie_site()

module.exports.push (ctx, next) ->
  @name 'HDP Hive & Kerberos Keytabs'
  {oozie_user, hadoop_group, oozie_site} = ctx.config.hdp
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  ctx.krb5_addprinc
    principal: oozie_site['oozie.service.HadoopAccessorService.kerberos.principal'].replace '_HOST', ctx.config.host
    randkey: true
    keytab: oozie_site['oozie.service.HadoopAccessorService.keytab.file']
    uid: oozie_user
    gid: hadoop_group
    kadmin_principal: kadmin_principal
    kadmin_password: kadmin_password
    kadmin_server: kadmin_server
  , (err, created) ->
    return next err if err
    next null, if created then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP Oozie # Environment"
  {oozie_user, hadoop_group, oozie_conf_dir} = ctx.config.hdp
  ctx.render
    source: "#{__dirname}/hdp/oozie/oozie-env.sh"
    destination: "#{oozie_conf_dir}/oozie-env.sh"
    context: ctx
    local_source: true
    uid: oozie_user
    gid: hadoop_group
    mode: 0o0755
  , (err, rendered) ->
    next err, if rendered then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP Oozie # War"
  ctx.execute
    cmd: """
    cd /usr/lib/oozie/
    bin/oozie-setup.sh prepare-war
    bin/ooziedb.sh create -sqlfile oozie.sql -run Validate DB Connection
    """
    not_if_exists: '/var/lib/oozie/oozie-server/webapps/oozie.war'
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP Oozie # Start"
  lifecycle.oozie_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP Oozie # Check"
  {oozie_user, hadoop_group, oozie_site} = ctx.config.hdp
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  ctx.krb5_addprinc
    principal: "oozie_test@#{realm}"
    randkey: true
    keytab: "/etc/security/keytabs/oozie_test.headless.keytab"
    uid: oozie_user
    gid: hadoop_group
    kadmin_principal: kadmin_principal
    kadmin_password: kadmin_password
    kadmin_server: kadmin_server
  , (err, created) ->
    return next err if err
    ctx.execute
      cmd: """
      kinit -kt /etc/security/keytabs/oozie_test.headless.keytab oozie_test && {
        oozie admin -oozie #{oozie_site['oozie.base.url']} -status
      }
      """
    , (err, executed, stdout) ->
      return next err if err
      return next new Error "Oozie not started" if stdout.trim() isnt 'System mode: NORMAL'
      return next null, ctx.PASS


  






