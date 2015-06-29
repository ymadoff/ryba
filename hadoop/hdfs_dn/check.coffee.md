
# Hadoop HDFS DataNode Check

Check the DataNode by uploading a file using the HDFS client and the HTTP REST
interface.

Run the command `./bin/ryba check -m ryba/hadoop/hdfs_dn` to check all the
DataNodes.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_dn/wait'
    # module.exports.push 'ryba/hadoop/hdfs_nn/wait'

    module.exports.push (ctx) ->
      require('../core').configure ctx
      require('../core_ssl').configure ctx
      require('../hdfs').configure ctx

## Check Disk Capacity

    module.exports.push name: 'HDFS DN # Check Disk Capacity', timeout: -1, label_true: 'CHECKED', handler: (ctx, next) ->
      {hdfs} = ctx.config.ryba
      protocol = if hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      port = hdfs.site["dfs.datanode.#{protocol}.address"].split(':')[1]
      ctx.execute
        cmd: mkcmd.hdfs ctx, "curl --negotiate -k -u : #{protocol}://#{ctx.config.host}:#{port}/jmx?qry=Hadoop:service=DataNode,name=DataNodeInfo"
      , (err, executed, stdout) ->
        throw err if err
        throw Error "Invalid Response" unless JSON.parse(stdout)?.beans[0]?.name is 'Hadoop:service=DataNode,name=DataNodeInfo'
       .then next
      # ctx.execute
      #   cmd: mkcmd.hdfs ctx, "curl --negotiate -k -u : #{protocol}://#{ctx.config.host}:#{port}/jmx?qry=Hadoop:service=DataNode,name=FSDatasetState-*"
      # , (err, executed, stdout) ->
      #   throw err if err
      #   data = JSON.parse stdout
      #   throw Error "Invalid Response" unless /^Hadoop:service=DataNode,name=FSDatasetState-.*/.test data?.beans[0]?.name
      #   remaining = data.beans[0].Remaining
      #   total = data.beans[0].Capacity
      #   ctx.log "Disk remaining: #{Math.round remaining}"
      #   ctx.log "Disk total: #{Math.round total}"
      #   percent = (total - remaining)/total * 100;
      #   ctx.log "WARNING: #{Math.round percent}" if percent > 90
      #  .then next

## Dependencies

    mkcmd = require '../../lib/mkcmd'
