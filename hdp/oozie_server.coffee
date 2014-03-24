
path = require 'path'
lifecycle = require './lib/lifecycle'
mkcmd = require './lib/mkcmd'

module.exports = []

module.exports.push 'phyla/utils/mysql_client'
module.exports.push 'phyla/hdp/core'

###
Oozie source code and examples are located in /usr/share/doc/oozie-4.0.0.2.0.6.0/

Note: to backup the oozie database in oozie, we must add the "hex-blob" option or 
we get an error while importing data. The mysqldump command does not escape all
charactere and the xml stored inside the database create syntax issues. Here's
an example:

```bash
mysqldump -uroot -ptest123 --hex-blob oozie > /data/1/oozie.sql
```

###
module.exports.push module.exports.configure = (ctx) ->
  require('../utils/mysql_server').configure ctx
  require('./oozie_').configure ctx
  {realm} = ctx.config.krb5_client
  {static_host} = ctx.config.hdp
  ctx.config.hdp.oozie_db_admin_username ?= ctx.config.mysql_server.username
  ctx.config.hdp.oozie_db_admin_password ?= ctx.config.mysql_server.password
  # dbhost = ctx.config.hdp.oozie_db_host ?= ctx.servers(action: 'phyla/utils/mysql_server')[0]
  dbhost = ctx.config.hdp.oozie_db_host ?= ctx.host_with_module 'phyla/utils/mysql_server'
  ctx.config.hdp.oozie_site['oozie.service.JPAService.jdbc.url'] ?= "jdbc:mysql://#{dbhost}:3306/oozie?createDatabaseIfNotExist=true"
  ctx.config.hdp.oozie_site['oozie.service.JPAService.jdbc.driver'] ?= 'com.mysql.jdbc.Driver'
  ctx.config.hdp.oozie_site['oozie.service.JPAService.jdbc.username'] ?= 'oozie'
  ctx.config.hdp.oozie_site['oozie.service.JPAService.jdbc.password'] ?= 'oozie123'
  # TODO: check if security is on
  ctx.config.hdp.oozie_site['oozie.service.AuthorizationService.security.enabled'] = 'false'
  ctx.config.hdp.oozie_site['oozie.service.HadoopAccessorService.kerberos.enabled'] = 'true'
  ctx.config.hdp.oozie_site['local.realm'] = "#{realm}"
  ctx.config.hdp.oozie_site['oozie.service.HadoopAccessorService.keytab.file'] = '/etc/security/keytabs/oozie.service.keytab'
  ctx.config.hdp.oozie_site['oozie.service.HadoopAccessorService.kerberos.principal'] = "oozie/#{ctx.config.host}@#{realm}"
  ctx.config.hdp.oozie_site['oozie.authentication.type'] = 'kerberos'
  ctx.config.hdp.oozie_site['oozie.authentication.kerberos.principal'] = "HTTP/#{ctx.config.host}@#{realm}"
  ctx.config.hdp.oozie_site['oozie.authentication.kerberos.keytab'] = '/etc/security/keytabs/spnego.service.keytab'
  # ctx.config.hdp.oozie_site['oozie.service.HadoopAccessorService.nameNode.whitelist'] = ''
  ctx.config.hdp.oozie_site['oozie.authentication.kerberos.name.rules'] = """
  
      RULE:[2:$1@$0]([rn]m@.*)s/.*/yarn/
      RULE:[2:$1@$0](jhs@.*)s/.*/mapred/
      RULE:[2:$1@$0]([nd]n@.*)s/.*/hdfs/
      RULE:[2:$1@$0](hm@.*)s/.*/hbase/
      RULE:[2:$1@$0](rs@.*)s/.*/hbase/
      DEFAULT
  """
  ctx.config.hdp.oozie_site['oozie.service.HadoopAccessorService.nameNode.whitelist'] ?= '' # Fix space value
  ctx.config.hdp.oozie_site['oozie.service.ProxyUserService.proxyuser.hive.hosts'] ?= "*"
  ctx.config.hdp.oozie_site['oozie.service.ProxyUserService.proxyuser.hive.groups'] ?= "*"
  ctx.config.hdp.oozie_site['oozie.service.ProxyUserService.proxyuser.hue.hosts'] ?= "*"
  ctx.config.hdp.oozie_site['oozie.service.ProxyUserService.proxyuser.hue.groups'] ?= "*"
  ctx.config.hdp.oozie_hadoop_config ?= {}
  ctx.config.hdp.oozie_hadoop_config['mapreduce.jobtracker.kerberos.principal'] ?= "mapred/#{static_host}@#{realm}"
  ctx.config.hdp.oozie_hadoop_config['yarn.resourcemanager.principal'] ?= "yarn/#{static_host}@#{realm}"
  ctx.config.hdp.oozie_hadoop_config['dfs.namenode.kerberos.principal'] ?= "hdfs/#{static_host}@#{realm}"
  ctx.config.hdp.oozie_hadoop_config['mapreduce.framework.name'] ?= "yarn"
  ctx.config.hdp.extjs ?= {}
  throw new Error "Missing extjs.source" unless ctx.config.hdp.extjs.source
  throw new Error "Missing extjs.destination" unless ctx.config.hdp.extjs.destination

module.exports.push name: 'HDP Oozie Server # Install', timeout: -1, callback: (ctx, next) ->
  ctx.service [
    name: 'oozie'
  ,
    name: 'oozie-client'
  ,
    name: 'extjs-2.2-1'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Oozie Server # Directories', callback: (ctx, next) ->
  {oozie_user, hadoop_group, oozie_data, oozie_conf_dir, oozie_log_dir, oozie_pid_dir, oozie_tmp_dir} = ctx.config.hdp
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
    return next err if err
    # Waiting for recursivity in ctx.mkdir
    ctx.execute [
      cmd: "chown -R #{oozie_user}:#{hadoop_group} #{oozie_data}"
    ,
      cmd: "chown -R #{oozie_user}:#{hadoop_group} #{oozie_conf_dir}/.."
    ,
      cmd: "chmod -R 755 #{oozie_conf_dir}/.."
    ], (err, executed) ->
      next err, if copied then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Oozie Server # Layout', callback: (ctx, next) ->
  ctx.mkdir
    destination: '/usr/lib/oozie/libext'
  , (err, created) ->
    next err, if created then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Oozie Server # ExtJS', callback: (ctx, next) ->
  ctx.execute
    cmd: 'cp /usr/share/HDP-oozie/ext-2.2.zip /usr/lib/oozie/libext/'
    not_if_exists: '/usr/lib/oozie/libext/ext-2.2.zip'
  , (err, copied) ->
    next err, if copied then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Oozie Server # LZO', callback: (ctx, next) ->
  ctx.execute
    cmd: 'cp /usr/lib/hadoop/lib/hadoop-lzo-0.5.0.jar /usr/lib/oozie/libext/'
    not_if_exists: '/usr/lib/oozie/libext/hadoop-lzo-0.5.0.jar'
  , (err, copied) ->
    next err, if copied then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Oozie Server # Mysql Driver', callback: (ctx, next) ->
  ctx.link
    source: '/usr/share/java/mysql-connector-java.jar'
    destination: '/usr/lib/oozie/libext/mysql-connector-java.jar'
  , (err, linked) ->
    return next err, ctx.PASS if err or not linked
    # Fore "HDP Oozie Server # War" callback to execute
    ctx.remove
      destination: '/var/lib/oozie/oozie-server/webapps/oozie.war'
      if_exists: true
    , (err) ->
      return next err, ctx.OK

module.exports.push name: 'HDP Oozie Server # Configuration', callback: (ctx, next) ->
  { oozie_user, hadoop_group, oozie_site, oozie_conf_dir, oozie_hadoop_config, hadoop_conf_dir } = ctx.config.hdp
  modified = false
  do_oozie_site = ->
    ctx.log 'Configure oozie-site.xml'
    ctx.hconfigure
      destination: "#{oozie_conf_dir}/oozie-site.xml"
      default: "#{__dirname}/files/oozie/oozie-site.xml"
      local_default: true
      properties: oozie_site
      uid: oozie_user
      gid: hadoop_group
      mode: 0o0755
      merge: true
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_hadoop_config()
  do_hadoop_config = ->
    ctx.log 'Configure hadoop-config.xml'
    ctx.hconfigure
      destination: "#{oozie_conf_dir}/hadoop-config.xml"
      default: "#{__dirname}/files/oozie/hadoop-config.xml"
      local_default: true
      properties: oozie_hadoop_config
      uid: oozie_user
      gid: hadoop_group
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
      uid: oozie_user
      gid: hadoop_group
    , (err, linked) ->
      return next err if err
      modified = true if linked
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_oozie_site()

module.exports.push name: 'HDP Oozie Server # Kerberos', callback: (ctx, next) ->
  {oozie_user, hadoop_group, oozie_site} = ctx.config.hdp
  {kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
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

module.exports.push name: 'HDP Oozie Server # SPNEGO', callback: (ctx, next) ->
  require('./hdfs').configure ctx
  require('./hdfs').spnego ctx, (err, status) ->
    # the group for the user oozie is hadoop,
    # so we can use the keytab generated by hdfs.spnego
    # and no copy it with different permissions
    return next err, status
    # return next err if err
    # ctx.copy
    #   source: '/etc/security/keytabs/spnego.service.keytab'
    #   destination: '/etc/security/keytabs/oozie_spnego.keytab'

module.exports.push name: 'HDP Oozie Server # MySQL', callback: (ctx, next) ->
  {oozie_db_admin_username, oozie_db_admin_password, oozie_db_host, oozie_site} = ctx.config.hdp
  username = oozie_site['oozie.service.JPAService.jdbc.username']
  password = oozie_site['oozie.service.JPAService.jdbc.password']
  escape = (text) -> text.replace(/[\\"]/g, "\\$&")
  cmd = "mysql -u#{oozie_db_admin_username} -p#{oozie_db_admin_password} -h#{oozie_db_host} -e "
  ctx.execute
    cmd: """
    if #{cmd} "use oozie"; then exit 2; fi
    #{cmd} "
    create database oozie;
    grant all privileges on oozie.* to '#{username}'@'localhost' identified by '#{password}';
    grant all privileges on oozie.* to '#{username}'@'%' identified by '#{password}';
    flush privileges;
    "
    """
    code_skipped: 2
  , (err, created, stdout, stderr) ->
    return next err, if created then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Oozie Server # War', callback: (ctx, next) ->
  # Note, as per Cloudera](https://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_topic_17_6.html),
  # `ooziedb.sh` must be done as the oozie Unix user, otherwise Oozie may fail to start or work properly because of incorrect file permissions,
  # however it was working without
  ctx.execute
    cmd: """
    cd /usr/lib/oozie/
    sudo -u oozie bin/oozie-setup.sh prepare-war
    bin/ooziedb.sh create -sqlfile oozie.sql -run Validate DB Connection
    """
    not_if_exists: '/var/lib/oozie/oozie-server/webapps/oozie.war'
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Oozie Server # Share lib', callback: (ctx, next) ->
  {oozie_user, hadoop_group} = ctx.config.hdp
  ctx.execute 
    cmd: mkcmd.hdfs ctx, """
    if hdfs dfs -ls /user/#{oozie_user}/share &>/dev/null; then exit 2; fi
    mkdir /tmp/ooziesharelib
    cd /tmp/ooziesharelib
    tar xzf /usr/lib/oozie/oozie-sharelib.tar.gz
    hdfs dfs -mkdir /user/#{oozie_user}
    hdfs dfs -put share /user/#{oozie_user}
    hdfs dfs -chown #{oozie_user}:#{hadoop_group} /user/#{oozie_user}
    hdfs dfs -chmod -R 755 /user/#{oozie_user}
    rm -rf /tmp/ooziesharelib
    """
    code_skipped: 2
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Oozie Server # Start', callback: (ctx, next) ->
  lifecycle.oozie_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

# module.exports.push name: 'HDP Oozie Server # Test User', callback: (ctx, next) ->
#   {oozie_user, hadoop_group, oozie_site
#    oozie_test_principal, oozie_test_password} = ctx.config.hdp
#   {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
#   ctx.krb5_addprinc
#     principal: oozie_test_principal
#     password: oozie_test_password
#     uid: oozie_user
#     gid: hadoop_group
#     kadmin_principal: kadmin_principal
#     kadmin_password: kadmin_password
#     kadmin_server: kadmin_server
#   , (err, created) ->
#     return next err if err
#     ctx.execute
#       cmd: ""
#     , (err, executed) ->
#       next err, if created then ctx.OK else ctx.PASS


  






