
# Falcon

[Apache Falcon][falcon] is a data processing and management solution for Hadoop designed
for data motion, coordination of data pipelines, lifecycle management, and data
discovery. Falcon enables end consumers to quickly onboard their data and its
associated processing and management tasks on Hadoop clusters.

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('masson/core/krb5_client').configure ctx
      require('../lib/base').configure ctx
      # require('masson/commons/java').configure ctx
      # require('../hadoop/core').configure ctx
      # require('./client').configure ctx
      {realm} = ctx.config.ryba
      falcon = ctx.config.ryba.falcon ?= {}
      # Layout
      falcon.falcon_conf_dir ?= '/etc/falcon/conf'
      # User
      falcon.user = name: falcon.user if typeof falcon.user is 'string'
      falcon.user ?= {}
      falcon.user.name ?= 'falcon'
      falcon.user.system ?= true
      falcon.user.gid ?= 'falcon'
      falcon.user.comment ?= 'Falcon User'
      falcon.user.home ?= '/var/lib/falcon'
      falcon.user.groups ?= ['hadoop']
      # Group
      falcon.group = name: falcon.group if typeof falcon.group is 'string'
      falcon.group ?= {}
      falcon.group.name ?= 'falcon'
      falcon.group.system ?= true
      # Runtime
      falcon.runtime ?= {}
      # Runtime (http://falcon.incubator.apache.org/Security.html)
      nn_contexts = ctx.contexts 'ryba/hadoop/hdfs_nn', require('../hadoop/hdfs_nn').configure
      # nn_rcp = nn_contexts[0].config.ryba.core_site['fs.defaultFS']
      # nn_protocol = if nn_contexts[0].config.ryba.hdfs.site['HTTP_ONLY'] then 'http' else 'https'
      # nn_nameservice = if nn_contexts[0].config.ryba.hdfs.site['dfs.nameservices'] then ".#{nn_contexts[0].config.ryba.hdfs.site['dfs.nameservices']}" else ''
      # nn_shortname = if nn_contexts.length then ".#{nn_contexts[0].config.shortname}" else ''
      # nn_http = ctx.config.ryba.hdfs.site["dfs.namenode.#{nn_protocol}-address#{nn_nameservice}#{nn_shortname}"] 
      nn_principal = nn_contexts[0].config.ryba.hdfs.site['dfs.namenode.kerberos.principal']
      falcon.startup ?= {}
      falcon.startup['prism.falcon.local.endpoint'] ?= "http://#{ctx.config.host}:16000/"
      falcon.startup['*.falcon.authentication.type'] ?= 'kerberos'
      falcon.startup['*.falcon.service.authentication.kerberos.principal'] ?= "#{falcon.user.name}/#{ctx.config.host}@#{realm}"
      falcon.startup['*.falcon.service.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/falcon.service.keytab'
      falcon.startup['*.dfs.namenode.kerberos.principal'] ?= "#{nn_principal}"
      falcon.startup['*.falcon.http.authentication.type=kerberos'] ?= 'kerberos'
      falcon.startup['*.falcon.http.authentication.token.validity'] ?= '36000'
      falcon.startup['*.falcon.http.authentication.signature.secret'] ?= 'falcon' # Change this
      falcon.startup['*.falcon.http.authentication.cookie.domain'] ?= ''
      falcon.startup['*.falcon.http.authentication.kerberos.principal'] ?= "HTTP/#{ctx.config.host}@#{realm}"
      falcon.startup['*.falcon.http.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab'
      falcon.startup['*.falcon.http.authentication.kerberos.name.rules'] ?= 'DEFAULT'
      falcon.startup['*.falcon.http.authentication.blacklisted.users'] ?= ''
      # Authorization Configuration
      # falcon.startup['*.falcon.security.authorization.enabled'] ?= 'true'
      # falcon.startup['*.falcon.security.authorization.provider'] ?= 'org.apache.falcon.security.DefaultAuthorizationProvider'
      # falcon.startup['*.falcon.security.authorization.superusergroup'] ?= 'falcon'
      # falcon.startup['*.falcon.security.authorization.admin.users'] ?= "#{falcon.user.name}"
      # falcon.startup['*.falcon.security.authorization.admin.groups'] ?= "#{falcon.group.name}"
      # falcon.startup['*.falcon.enableTLS'] ?= 'true'
      # falcon.startup['*.keystore.file'] ?= '/path/to/keystore/file'
      # falcon.startup['*.keystore.password'] ?= 'password'
      # falcon.startup[''] ?= ''

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/falcon/backup'

    module.exports.push commands: 'check', modules: 'ryba/falcon/check'

    module.exports.push commands: 'install', modules: [
      'ryba/falcon/install'
      'ryba/falcon/start'
      'ryba/falcon/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/falcon/start'

    module.exports.push commands: 'status', modules: 'ryba/falcon/status'

    module.exports.push commands: 'stop', modules: 'ryba/falcon/stop'

[falcon]: http://falcon.incubator.apache.org/
