
# HBase ThriftServer

    module.exports = []

    module.exports.push module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('../hadoop/hdfs').configure ctx
      require('./_').configure ctx
      {realm} = ctx.config.ryba
      hbase = ctx.config.ryba.hbase ?= {}
      # Secure Client Configuration
      # TODO: add acl (http://hbase.apache.org/book.html#d3314e6371)
      hbase.site['hbase.thrift.kerberos.principal'] ?= "hbase_thrift/_HOST@#{realm}" # Dont forget `grant 'thrift_server', 'RWCA'`
      hbase.site['hbase.thrift.keytab.file'] ?= '#{hbase.conf_dir}/thrift.service.keytab'
      
