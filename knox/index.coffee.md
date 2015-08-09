
# Knox

The Apache Knox Gateway is a REST API gateway for interacting with Apache Hadoop
clusters. The gateway provides a single access point for all REST interactions
with Hadoop clusters.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'

## Configure

    module.exports.configure = (ctx) ->
      knox = ctx.config.ryba.knox ?= {}
      # Load configurations
      require('masson/core/iptables').configure ctx
      require('../hadoop/core').configure ctx
      # require('../hadoop/yarn_rm').configure ctx
      # require('../hive/webhcat').configure ctx
      # require('../oozie/server').configure ctx
      # {core_site, hive, webhcat, oozie} = ctx.config.ryba
      # Layout
      knox.conf_dir ?= '/etc/knox/conf'
      # User
      knox.user = name: knox.user if typeof knox.user is 'string'
      knox.user ?= {}
      knox.user.name ?= 'knox'
      knox.user.system ?= true
      knox.user.comment ?= 'Knox Gateway User'
      knox.user.home ?= '/var/lib/knox'
      # Group
      knox.group = name: knox.group if typeof knox.group is 'string'
      knox.group ?= {}
      knox.group.name ?= 'knox'
      knox.group.system ?= true
      knox.user.gid = knox.group.name
      # Kerberos
      knox.krb5_user ?= {}
      knox.krb5_user.principal ?= "#{knox.user.name}/#{ctx.config.host}@#{ctx.config.ryba.realm}"
      knox.krb5_user.keytab ?= '/etc/security/keytabs/knox.service.keytab'
      # Security
      knox.master_secret ?= 'knox_master_secret_123'
      # Configuration
      knox.site ?= {}
      knox.site['gateway.port'] ?= '8443'
      knox.site['gateway.path'] ?= 'gateway'
      knox.site['java.security.krb5.conf'] ?= '/etc/krb5.conf'
      knox.site['java.security.auth.login.config'] ?= "#{knox.conf_dir}/knox.jaas"
      knox.site['gateway.hadoop.kerberos.secured'] ?= 'true'
      knox.site['sun.security.krb5.debug'] ?= 'true'
      # Calculate Services config values for default topology
      rm_contexts = ctx.contexts 'ryba/hadoop/yarn_rm', require('../hadoop/yarn_rm').configure
      rm_shortname = if rm_contexts.length > 1 then ".#{rm_contexts[0].config.shortname}" else ''      
      rm_address = rm_contexts[0].config.ryba.yarn.site["yarn.resourcemanager.address#{rm_shortname}"]
      nn_hosts = ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
      nn_context = ctx.contexts 'ryba/hadoop/hdfs_nn', require('../hadoop/hdfs_nn').configure
      # require('../hadoop/hdfs_nn').configure hdfs_ctx
      # console.log require('util').inspect hdfs_ctx.config.ryba.hdfs
      # webhcat_host = ctx.host_with_module 'ryba/hive/webhcat'
      # webhcat_port = webhcat.site['templeton.port']
      # hbase_hosts = ctx.hosts_with_module 'ryba/hbase/master'
      # hive_hosts = ctx.hosts_with_module 'ryba/hive/hcatalog'
      # hive_ctx = ctx.hosts[hive_hosts[0]]
      # require('../hive/hcatalog').configure hive_ctx
      # hive_mode = hive_ctx.config.ryba.hive.site['hive.server2.transport.mode']
      # throw Error "Invalid property \"hive.server2.transport.mode\", expect \"http\"" unless hive_mode is 'http'
      # hive_port = hive_ctx.config.ryba.hive.site['hive.server2.thrift.http.port']
      # knox.services ?= {}
      # knox.services['namenode'] ?=
      # knox.services['jobtracker'] ?= "rpc://#{rm_address}"
      # knox.services['webhdfs'] ?= "https://#{webhdfs_host}:50470/webhdfs"
      # knox.services['webhcat'] ?= "http://#{webhcat_host}:#{webhcat_port}/templeton"
      # knox.services['oozie'] ?= "#{oozie.site['oozie.base.url']}"
      # knox.services['webhbase'] ?= "http://#{hbase_host}:60080" if hbase_host
      # knox.services['hive'] ?= "http://#{hive_host}:#{hive_port}/cliservice" if hive_host
      knox.topologies ?= {}
      topology = knox.topologies[ctx.config.ryba.nameservice] ?= {}
      topology.providers ?= {}
      topology.providers.ShiroProvider ?=
        role: 'authentication'
        config:
          'sessionTimeout': 30
          'main.ldapRealm': 'org.apache.hadoop.gateway.shirorealm.KnoxLdapRealm'
          'main.ldapContextFactory': 'org.apache.hadoop.gateway.shirorealm.KnoxLdapContextFactory'
          'main.ldapRealm.contextFactory': '$ldapContextFactory'
          'main.ldapRealm.userDnTemplate': 'uid={0},ou=people,dc=hadoop,dc=apache,dc=org'
          'main.ldapRealm.contextFactory.url': 'ldap://localhost:33389'
          'main.ldapRealm.contextFactory.authenticationMechanism': 'simple'
          'urls./**':'authcBasic'
      topology.providers.Default ?= role: 'identity-assertion'
      topology.providers.static ?=
        role: 'hostmap'
        config:
          localhost: 'sandbox,sandbox.hortonworks.com'
      topology.providers.haProvider ?=
        role: 'ha'
        config: WEBHDFS: 'maxFailoverAttempts=3;failoverSleep=1000;maxRetryAttempts=300;retrySleep=1000;enabled=true'
      topology.services ?= {}
      topology.services['namenode'] ?= "#{ctx.config.ryba.core_site['fs.defaultFS']}"
       # If condition is mandatory since it is undefined at the first execs
      topology.services['jobtracker'] ?= "rpc://#{rm_address}" if rm_address?
      topology.services.webhdfs ?= nn_context.config.ryba.hdfs.site["dfs.namenode.https-address.#{ryba.nameservice}.#{nn_host.slit('.')[0]}"] for nn_host in nn_hosts
      # knox.services['webhdfs'] ?= "https://#{webhdfs_host}:50470/webhdfs"
      # knox.services['webhcat'] ?= "http://#{webhcat_host}:#{webhcat_port}/templeton"
      # knox.services['oozie'] ?= "#{oozie.site['oozie.base.url']}"
      # knox.services['webhbase'] ?= "http://#{hbase_host}:60080" if hbase_host
      # knox.services['hive'] ?= "http://#{hive_host}:#{hive_port}/cliservice" if hive_host
        # services:
        #   NAMENODE: 'hfds://localhost:8020'
        #   JOBTRACKER: 'rpc://localhost:8050'
        #   WEBHDFS: ['http://host1:50070/webhdfs', 'http://host1:50070/webhdfs']
        #   WEBHCAT: 'http://localhost:50111/templeton'

    module.exports.push commands: 'check', modules: 'ryba/knox/check'

    module.exports.push commands: 'install', modules: [
      'ryba/knox/install'
      #'ryba/knox/start'
      #'ryba/knox/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/knox/start'

    module.exports.push commands: 'stop', modules: 'ryba/knox/stop'

    module.exports.push commands: 'status', modules: 'ryba/knox/status'
