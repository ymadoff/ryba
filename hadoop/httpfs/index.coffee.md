
# HDFS HttpFS

HttpFS is a server that provides a REST HTTP gateway supporting all HDFS File
System operations (read and write). And it is inteoperable with the webhdfs REST
HTTP API.

    module.exports = []

## Configuration

The default configuration is located inside the source code in the location
"hadoop-hdfs-project/hadoop-hdfs-httpfs/src/main/resources/httpfs-default.xml".

    module.exports.configure = (ctx)->
      {realm} = ctx.config.ryba
      require('../core').configure ctx # Get "core_site['hadoop.security.auth_to_local']"
      httpfs = ctx.config.ryba.httpfs ?= {}
      # Environment, layout
      httpfs.pid_dir ?= '/var/run/httpfs'
      httpfs.conf_dir ?= '/etc/hadoop-httpfs/conf'
      httpfs.log_dir ?= '/var/log/hadoop-httpfs'
      httpfs.tmp_dir ?= '/var/tmp/hadoop-httpfs'
      httpfs.http_port ?= '14000'
      httpfs.http_admin_port ?= '14001'
      httpfs.catalina_home ?= '/etc/hadoop-httpfs/tomcat-deployment'
      httpfs.catalina_opts ?= ''
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
      # Site
      httpfs.site ?= {}
      httpfs.site['httpfs.hadoop.config.dir'] ?= '/etc/hadoop/conf'
      httpfs.site['kerberos.realm'] ?= "#{realm}"
      httpfs.site['httpfs.hostname'] ?= "#{ctx.config.host}"
      httpfs.site['httpfs.authentication.type'] ?= 'kerberos'
      httpfs.site['httpfs.authentication.kerberos.principal'] ?= "HTTP/#{ctx.config.host}@#{realm}" # Default to "HTTP/${httpfs.hostname}@${kerberos.realm}"
      httpfs.site['httpfs.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab' # Default to "${user.home}/httpfs.keytab"
      httpfs.site['httpfs.hadoop.authentication.type'] ?= 'kerberos'
      httpfs.site['httpfs.hadoop.authentication.kerberos.keytab'] ?= '/etc/hadoop-httpfs/conf/httpfs.keytab' # Default to "${user.home}/httpfs.keytab"
      httpfs.site['httpfs.hadoop.authentication.kerberos.principal'] ?= "#{httpfs.user.name}/#{ctx.config.host}@#{realm}" # Default to "${user.name}/${httpfs.hostname}@${kerberos.realm}"
      httpfs.site['httpfs.authentication.kerberos.name.rules'] ?= ctx.config.ryba.core_site['hadoop.security.auth_to_local']
      hdfs_ctxs = ctx.contexts ['ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn']
      for hdfs_ctx in hdfs_ctxs
        hdfs_ctx.config.ryba ?= {}
        hdfs_ctx.config.ryba.core_site ?= {}
        hdfs_ctx.config.ryba.core_site["hadoop.proxyuser.#{httpfs.user.name}.hosts"] ?= '*'
        hdfs_ctx.config.ryba.core_site["hadoop.proxyuser.#{httpfs.user.name}.groups"] ?= '*'

    module.exports.push commands: 'check', modules: 'ryba/hadoop/httpfs/check'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/httpfs/install'
      'ryba/hadoop/httpfs/start'
      'ryba/hadoop/httpfs/check'
    ]

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/httpfs/stop'

    module.exports.push commands: 'status', modules: 'ryba/hadoop/httpfs/status'
