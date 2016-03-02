

# HBase Client Configuration

    module.exports = handler: ->
      hbase = @config.ryba.hbase ?= {}
      hbase.site ?= {}
      hm_ctxs = @contexts 'ryba/hbase/master', require('../master/configure').handler
      throw Error "No HBase Master" unless hm_ctxs.length >= 1
      hbase.site ?= {}
      ## Configuration HBase Replication
      hbase.site['hbase.replication'] ?= hm_ctxs[0].config.ryba.hbase.master.site['hbase.replication']

## Configure Security

      hbase.site['hbase.security.authentication'] = hm_ctxs[0].config.ryba.hbase.master.site['hbase.security.authentication']
      hbase.site['hbase.security.authorization'] = hm_ctxs[0].config.ryba.hbase.master.site['hbase.security.authorization']
      hbase.site['hbase.superuser'] = hm_ctxs[0].config.ryba.hbase.master.site['hbase.superuser']
      hbase.site['hbase.rpc.engine'] ?= hm_ctxs[0].config.ryba.hbase.master.site['org.apache.hadoop.hbase.ipc.SecureRpcEngine']
      hbase.site['hbase.bulkload.staging.dir'] = hm_ctxs[0].config.ryba.hbase.master.site['hbase.bulkload.staging.dir']
      hbase.site['hbase.master.kerberos.principal'] = hm_ctxs[0].config.ryba.hbase.master.site['hbase.master.kerberos.principal']
      hbase.site['hbase.regionserver.kerberos.principal'] = hm_ctxs[0].config.ryba.hbase.master.site['hbase.regionserver.kerberos.principal']

## Client Configuration HA

      if hm_ctxs.length > 1
        hbase.site['hbase.ipc.client.specificThreadForWriting'] ?= 'true'
        hbase.site['hbase.client.primaryCallTimeout.get'] ?= '10000'
        hbase.site['hbase.client.primaryCallTimeout. multiget'] ?= '10000'
        hbase.site['hbase.client.primaryCallTimeout.scan'] ?= '1000000'
        hbase.site['hbase.meta.replicas.use'] ?= 'true'
