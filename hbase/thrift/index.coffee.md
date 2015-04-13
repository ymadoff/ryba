
# HBase ThriftServer

[Apache Thrift](http://wiki.apache.org/hadoop/Hbase/ThriftApi) is a cross-platform, cross-language development framework.
HBase includes a Thrift API and filter language. The Thrift API relies on client and server processes.
Thrift is both cross-platform and more lightweight than REST for many operations. 

    module.exports = []      
    #  {realm} = ctx.config.ryba
     # hbase = ctx.config.ryba.hbase ?= {}

      # Secure Client Configuration
      # TODO: add acl (http://hbase.apache.org/book.html#d3314e6371)
      #hbase.site['hbase.thrift.kerberos.principal'] ?= "hbase_thrift/_HOST@#{realm}" # Dont forget `grant 'thrift_server', 'RWCA'`
      #hbase.site['hbase.thrift.keytab.file'] ?= '#{hbase.conf_dir}/thrift.service.keytab'
      ## Configuration

See [REST Gateway Impersonation Configuration][impersonation].

[impersonation]: http://hbase.apache.org/book.html#d3314e6371

    module.exports.configure = (ctx) ->  
      require('masson/core/iptables').configure ctx
      require('../_').configure ctx
      require('../../hadoop/core_ssl').configure ctx
      {realm, core_site, ssl_server, hbase} = ctx.config.ryba
      hbase.site['hbase.thrift.port'] ?= '9090' # Default to "8080"
      hbase.site['hbase.thrift.info.port'] ?= '9095' # Default to "8085"
      hbase.site['hbase.thrift.ssl.enabled'] ?= 'true'
      hbase.site['hbase.thrift.ssl.keystore.store'] ?= ssl_server['ssl.server.keystore.location']
      hbase.site['hbase.thrift.ssl.keystore.password'] ?= ssl_server['ssl.server.keystore.password']
      hbase.site['hbase.thrift.ssl.keystore.keypassword'] ?= ssl_server['ssl.server.keystore.keypassword']
      hbase.site['hbase.thrift.kerberos.principal'] ?= "hbase_thrift/_HOST@#{realm}" # Dont forget `grant 'rest_server', 'RWCA'`
      hbase.site['hbase.thrift.keytab.file'] ?= "#{hbase.conf_dir}/thrift.service.keytab"
      hbase.site['hbase.thrift.authentication.type'] ?= 'kerberos'
      hbase.site['hbase.thrift.authentication.kerberos.principal'] ?= "HTTP/_HOST@#{realm}"
      # hbase.site['hbase.thrift.authentication.kerberos.keytab'] ?= "#{hbase.conf_dir}/hbase.service.keytab"
      hbase.site['hbase.thrift.authentication.kerberos.keytab'] ?= core_site['hadoop.http.authentication.kerberos.keytab']
      m_ctxs = ctx.contexts 'ryba/hbase/master'
      hbase.site['hbase.master.kerberos.principal'] = m_ctxs[0].config.ryba.hbase.site['hbase.master.kerberos.principal']
      hbase.site['hbase.regionserver.kerberos.principal'] = m_ctxs[0].config.ryba.hbase.site['hbase.regionserver.kerberos.principal']
      hbase.thrift = []
      hbase.thrift.autoconf = []
      hbase.thrift.autoconf.url = 'http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz';
      hbase.thrift.autoconf.url = '/Users/Bakalian/ryba/ryba-cluster/resources/autoconf.tar.gz';
      hbase.thrift.autoconf.destination = '/tmp/autoconf.tar.gz'
      hbase.thrift.autoconf.tmp = '/tmp/autoconf'
      hbase.thrift.autoconf.version = '2.69'
      hbase.thrift.automake = []
      hbase.thrift.automake.url = 'http://ftp.gnu.org/gnu/automake/automake-1.14.tar.gz';
      hbase.thrift.automake.url = '/Users/Bakalian/ryba/ryba-cluster/resources/automake-1.14.tar.gz';
      hbase.thrift.automake.destination = '/tmp/automake.tar.gz'
      hbase.thrift.automake.tmp = '/tmp/automake'
      hbase.thrift.automake.version = '1.14'
      hbase.thrift.bison = []
      hbase.thrift.bison.url = 'http://ftp.gnu.org/gnu/bison/bison-2.5.1.tar.gz';
      hbase.thrift.bison.url = '/Users/Bakalian/ryba/ryba-cluster/resources/bison.tar.gz';
      hbase.thrift.bison.destination = '/tmp/bison.tar.gz'
      hbase.thrift.bison.tmp = '/tmp/bison'
      hbase.thrift.bison.version = '2.5.1'
      hbase.thrift.compiler = []
      hbase.thrift.compiler.url = 'https://git-wip-us.apache.org/repos/asf/thrift.git';
      hbase.thrift.compiler.url = '/Users/Bakalian/ryba/ryba-cluster/resources/compiler.tar.gz';
      hbase.thrift.compiler.destination = '/tmp/bison.tar.gz'
      hbase.thrift.compiler.tmp = '/tmp/bison'
      hbase.thrift.destination= '/usr/lib/thrift/'

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/hbase/rest/backup'

    module.exports.push commands: 'check', modules: 'ryba/hbase/thrift/check'

    module.exports.push commands: 'install', modules: [
      'ryba/hbase/thrift/install'
      'ryba/hbase/thrift/start'
      'ryba/hbase/thrift/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hbase/thrift/start'

    module.exports.push commands: 'status', modules: 'ryba/hbase/thrift/status'

    module.exports.push commands: 'stop', modules: 'ryba/hbase/thrift/stop'