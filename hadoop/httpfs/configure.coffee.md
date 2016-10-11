
# HDFS HttpFS Configure

The default configuration is located inside the source code in the location
"hadoop-hdfs-project/hadoop-hdfs-httpfs/src/main/resources/httpfs-default.xml".

    module.exports = ->
      {realm} = @config.ryba
      hdfs_ctxs = @contexts ['ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn']
      httpfs = @config.ryba.httpfs ?= {}
      # Environment, layout
      httpfs.pid_dir ?= '/var/run/httpfs'
      httpfs.conf_dir ?= '/etc/hadoop-httpfs/conf'
      httpfs.log_dir ?= '/var/log/hadoop-httpfs'
      httpfs.tmp_dir ?= '/var/tmp/hadoop-httpfs'
      httpfs.http_port ?= '14000'
      httpfs.http_admin_port ?= '14001'
      httpfs.catalina ?= {}
      httpfs.catalina_home ?= '/etc/hadoop-httpfs/tomcat-deployment'
      httpfs.catalina_opts ?= ''
      httpfs.catalina.opts ?= {}
      # Group
      httpfs.group = name: httpfs.group if typeof httpfs.group is 'string'
      httpfs.group ?= {}
      httpfs.group.name ?= 'httpfs'
      httpfs.group.system ?= true
      # User
      httpfs.user ?= {}
      httpfs.user = name: httpfs.user if typeof httpfs.user is 'string'
      httpfs.user.name ?= httpfs.group.name
      httpfs.user.system ?= true
      httpfs.user.comment ?= 'HttpFS User'
      httpfs.user.home = "/var/lib/#{httpfs.user.name}"
      httpfs.user.gid = httpfs.group.name
      httpfs.user.groups ?= 'hadoop'
      # env
      httpfs.env ?= {}
      httpfs.env.HTTPFS_SSL_ENABLED ?= 'true' # Default is "false"
      httpfs.env.HTTPFS_SSL_KEYSTORE_FILE ?= "#{httpfs.conf_dir}/keystore" # Default is "${HOME}/.keystore"
      httpfs.env.HTTPFS_SSL_KEYSTORE_PASS ?= 'ryba123' # Default to "password"
      # Site
      httpfs.site ?= {}
      httpfs.site['httpfs.hadoop.config.dir'] ?= '/etc/hadoop/conf'
      httpfs.site['kerberos.realm'] ?= "#{realm}"
      httpfs.site['httpfs.hostname'] ?= "#{@config.host}"
      httpfs.site['httpfs.authentication.type'] ?= 'kerberos'
      httpfs.site['httpfs.authentication.kerberos.principal'] ?= "HTTP/#{@config.host}@#{realm}" # Default to "HTTP/${httpfs.hostname}@${kerberos.realm}"
      httpfs.site['httpfs.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab' # Default to "${user.home}/httpfs.keytab"
      httpfs.site['httpfs.hadoop.authentication.type'] ?= 'kerberos'
      httpfs.site['httpfs.hadoop.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/httpfs.service.keytab' # Default to "${user.home}/httpfs.keytab"
      httpfs.site['httpfs.hadoop.authentication.kerberos.principal'] ?= "#{httpfs.user.name}/#{@config.host}@#{realm}" # Default to "${user.name}/${httpfs.hostname}@${kerberos.realm}"
      httpfs.site['httpfs.authentication.kerberos.name.rules'] ?= @config.ryba.core_site['hadoop.security.auth_to_local']
      for hdfs_ctx in hdfs_ctxs
        hdfs_ctx.config.ryba ?= {}
        hdfs_ctx.config.ryba.core_site ?= {}
        hdfs_ctx.config.ryba.core_site["hadoop.proxyuser.#{httpfs.user.name}.hosts"] ?= @contexts('ryba/hadoop/httpfs').map((ctx) -> ctx.config.host).join ','
        hdfs_ctx.config.ryba.core_site["hadoop.proxyuser.#{httpfs.user.name}.groups"] ?= '*'
      # Log4J
      if @config.log4j?.remote_host? && @config.log4j?.remote_port?
        httpfs.catalina.opts['httpfs.log.server.logger'] = 'INFO,httpfs,socket'
        httpfs.catalina.opts['httpfs.log.audit.logger'] = 'INFO,httpfsaudit,socket'
        httpfs.catalina.opts['httpfs.log.remote_host'] = @config.log4j.remote_host
        httpfs.catalina.opts['httpfs.log.remote_port'] = @config.log4j.remote_port
