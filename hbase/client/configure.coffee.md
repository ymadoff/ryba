
# HBase Client Configuration

    module.exports = ->
      ryba = @config.ryba ?= {}
      hbase = @config.ryba.hbase ?= {}
      hm_ctxs = @contexts 'ryba/hbase/master', require('../master/configure').handler
      throw Error "No HBase Master" unless hm_ctxs.length >= 1
      hbase.site ?= {}
      hbase.client ?= {}

# Identities

      hbase.group = merge hm_ctxs[0].config.ryba.hbase.group, hbase.group
      hbase.user = merge hm_ctxs[0].config.ryba.hbase.user, hbase.user
      hbase.admin = merge hm_ctxs[0].config.ryba.hbase.admin, hbase.admin

## Layout

      hbase.conf_dir ?= '/etc/hbase/conf'
      hbase.log_dir ?= '/var/log/hbase'

## Test

      hbase.client.test ?= {}
      hbase.client.test.namespace ?= "ryba_check_client_#{@config.shortname}"
      hbase.client.test.table ?= 'a_table'

## Environment

      hbase.env ?=  {}
      hbase.env['JAVA_HOME'] ?= "#{@config.java}"
      hbase.env['HBASE_LOG_DIR'] ?= "#{hbase.log_dir}"
      hbase.env['HBASE_OPTS'] ?= '-ea -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode' # Default in HDP companion file
      hbase.env['HBASE_MASTER_OPTS'] ?= '-Xmx2048m' # Default in HDP companion file
      hbase.env['HBASE_REGIONSERVER_OPTS'] ?= '-Xmn200m -Xms4096m -Xmx4096m' # Default in HDP companion file

## Configure Security

      hbase.site['hbase.security.authentication'] = hm_ctxs[0].config.ryba.hbase.master.site['hbase.security.authentication']
      hbase.site['hbase.security.authorization'] = hm_ctxs[0].config.ryba.hbase.master.site['hbase.security.authorization']
      hbase.site['hbase.superuser'] = hm_ctxs[0].config.ryba.hbase.master.site['hbase.superuser']
      hbase.site['hbase.rpc.engine'] ?= hm_ctxs[0].config.ryba.hbase.master.site['hbase.rpc.engine']
      hbase.site['hbase.bulkload.staging.dir'] = hm_ctxs[0].config.ryba.hbase.master.site['hbase.bulkload.staging.dir']
      hbase.site['hbase.master.kerberos.principal'] = hm_ctxs[0].config.ryba.hbase.master.site['hbase.master.kerberos.principal']
      hbase.site['hbase.regionserver.kerberos.principal'] = hm_ctxs[0].config.ryba.hbase.master.site['hbase.regionserver.kerberos.principal']

## HBase Replication

      hbase.site['hbase.replication'] ?= hm_ctxs[0].config.ryba.hbase.master.site['hbase.replication']

## Client Configuration HA Reads

      if parseInt(hm_ctxs[0].config.ryba.hbase.master.site['hbase.meta.replica.count']) > 1
        hbase.site['hbase.ipc.client.specificThreadForWriting'] ?= 'true'
        hbase.site['hbase.client.primaryCallTimeout.get'] ?= '10000'
        hbase.site['hbase.client.primaryCallTimeout.multiget'] ?= '10000'
        hbase.site['hbase.client.primaryCallTimeout.scan'] ?= '1000000'
        hbase.site['hbase.meta.replicas.use'] ?= 'true'

## Configuration Distributed mode

      for property in [
        'zookeeper.znode.parent'
        'hbase.cluster.distributed'
        'hbase.rootdir'
        'hbase.zookeeper.quorum'
        'hbase.zookeeper.property.clientPort'
        'dfs.domain.socket.path'
      ] then hbase.site[property] ?= hm_ctxs[0].config.ryba.hbase.master.site[property]

## Dependencies

    {merge} = require 'nikita/lib/misc'
