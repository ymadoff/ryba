  
## HBase Cluster Replication

Deploy HBase replication to point slave cluster.
  
    module.exports =  header: 'HBase Client Replication', handler: ->
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
