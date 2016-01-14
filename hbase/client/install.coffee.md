
# HBase Client Install

Install the HBase client package and configure it with secured access.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/mapred_client/install' # Required for using/checking mapreduce
    module.exports.push 'ryba/hbase'
    # module.exports.push require('./index').configure
    module.exports.push 'ryba/lib/hconfigure'
    module.exports.push 'ryba/lib/write_jaas'

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master,
RegionServer, and HBase client host machines.

    module.exports.push header: 'HBase Client # Zookeeper JAAS', timeout: -1, handler: ->
      {hbase} = @config.ryba
      @write_jaas
        destination: "#{hbase.conf_dir}/hbase-client.jaas"
        content: Client:
          useTicketCache: 'true'
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o644

## Configure

Note, we left the permission mode as default, Master and RegionServer need to

    module.exports.push header: 'HBase Client # Configure', handler: ->
      {hbase} = @config.ryba
      @hconfigure
        destination: "#{hbase.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../resources/hbase-site.xml"
        local_default: true
        properties: hbase.site
        merge: false
        uid: hbase.user.name
        gid: hbase.group.name
        backup: true

## HBase Cluster Replication

    # module.exports.push 'ryba/hbase/master/wait'

Deploy HBase replication to point slave cluster.
This module can be runned on one node, so it is runned on the first hbase-master.

    module.exports.push header: 'HBase Client # Replication', skip: true, handler: ->
      {hbase} = @config.ryba
      for k, cluster of hbase.replicated_clusters
        peer_key = parseInt(k) + 1
        peer_value = "#{cluster.zookeeper_quorum}:#{cluster.zookeeper_port}:#{cluster.zookeeper_node}"
        if cluster.zookeeper_node != hbase.site['zookeeper.znode.parent']
          msg_err = "Slave Cluster must have same zookeeper hbase node: #{cluster.zookeeper_node} instead of #{hbase.site['zookeeper.znode.parent']}"
          throw new Error msg_err
        else
          @execute
            cmd: mkcmd.hbase @, """
            hbase shell -n 2>/dev/null <<-CMD
              add_peer '#{peer_key}', '#{peer_value}'
            CMD
            """
            unless_exec: mkcmd.hbase @, "hbase shell -n 2>/dev/null <<< \"list_peers\" | grep '#{peer_key} #{peer_value} ENABLED'"

## Dependencies

    mkcmd = require '../../lib/mkcmd'