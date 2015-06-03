
# Hadoop HDFS NameNode Check

Check the health of the NameNode(s).

In HA mode, we need to ensure both NameNodes are installed before testing SSH
Fencing. Otherwise, a race condition may occur if a host attempt to connect
through SSH over another one where the public key isn't yet deployed.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_nn/wait'
    module.exports.push require('../hdfs').configure

## Check HTTP

    module.exports.push name: 'HDFS NN # Check HTTP', timeout: -1, label_true: 'CHECKED', handler: (ctx, next) ->
      {hdfs, active_nn_host} = ctx.config.ryba
      is_ha = ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      state = if not is_ha or active_nn_host is ctx.config.host then 'active' else 'standby'
      protocol = if hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      nameservice = if is_ha then ".#{ctx.config.ryba.hdfs.site['dfs.nameservices']}" else ''
      shortname = if is_ha then ".#{ctx.config.shortname}" else ''
      address = hdfs.site["dfs.namenode.#{protocol}-address#{nameservice}#{shortname}"]
      securityEnabled = protocol is 'https'
      ctx.execute
        cmd: mkcmd.hdfs ctx, "curl --negotiate -k -u : #{protocol}://#{address}/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus"
      , (err, executed, stdout) ->
        return next err if err
        data = JSON.parse stdout
        # After HDP2.2, the response needs some time before returning any beans
        return next Error "Invalid Response" unless Array.isArray data?.beans
        # return next Error "Invalid Response" unless /^Hadoop:service=NameNode,name=NameNodeStatus$/.test data?.beans[0]?.name
        # return next Error "WARNING: Invalid security (#{data.beans[0].SecurityEnabled}, instead of #{securityEnabled}" unless data.beans[0].SecurityEnabled is securityEnabled
      .then next

## Check Health

Connect to the provided NameNode to check its health. The NameNode is capable of
performing some diagnostics on itself, including checking if internal services
are running as expected. This command will return 0 if the NameNode is healthy,
non-zero otherwise. One might use this command for monitoring purposes.

Checkhealth return result is not completely implemented
See More http://hadoop.apache.org/docs/r2.0.2-alpha/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailability.html#Administrative_commands

    module.exports.push name: 'HDFS NN # Check HA Health', label_true: 'CHECKED', handler: (ctx, next) ->
      return next() unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      ctx.execute
        cmd: mkcmd.hdfs ctx, "hdfs haadmin -checkHealth #{ctx.config.shortname}"
      .then next

## Check FSCK

Check for various inconsistencies on the overall filesystem. Use the command
`hdfs fsck -list-corruptfileblocks` to list the corrupted blocks.

    module.exports.push name: 'HDFS NN # Check FSCK', label_true: 'CHECKED', timeout: -1, retry: 3, wait: 60000, handler: (ctx, next) ->
      ctx.execute
        cmd: mkcmd.hdfs ctx, "exec 5>&1; hdfs fsck / | tee /dev/fd/5 | tail -1 | grep HEALTHY 1>/dev/null"
      .then next

## Module Dependencies

    mkcmd = require '../../lib/mkcmd'
