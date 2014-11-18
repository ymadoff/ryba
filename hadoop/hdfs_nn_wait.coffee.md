
# HDFS NameNode Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs').configure

    module.exports.push name: 'Hadoop HDFS NN # Wait', timeout: -1, callback: (ctx, next) ->
      # {active_nn_host} = ctx.config.ryba
      # nn_ctx = ctx.hosts[active_nn_host]
      # require('./hdfs_nn').configure nn_ctx
      # protocol = if nn_ctx.config.ryba.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      # if ctx.host_with_module 'ryba/hadoop/hdfs_snn'
      #   port = nn_ctx.config.ryba.hdfs_site["dfs.namenode.#{protocol}-address"].split(':')[1]
      # else
      #   {nameservice, shortname} = nn_ctx.config.ryba
      #   port = nn_ctx.config.ryba.ha_client_config["dfs.namenode.#{protocol}-address.#{nameservice}.#{shortname}"].split(':')[1]
      # url = "https://#{active_nn_host}:#{port}/jmx?qry=Hadoop:service=NameNode,name=FSNamesystemState"
      # ctx.waitForExecution
      #   cmd: """
      #     mode=`curl -s -k --negotiate -u: '#{url}' | grep FSState | sed 's/^.*:.*"\\(.*\\)".*$/\\1/g'`
      #     if [ $mode != 'Operational' ] ; then exit 2; fi
      #     """
      #   code_skipped: 2
      #   interval: 3000
      # , (err) -> next err
      ctx.waitForExecution
        cmd: mkcmd.hdfs ctx, """
          hdfs dfsadmin -safemode get | grep OFF
          """
        interval: 3000
      , (err) -> next err

## Module Dependencies

    mkcmd = require '../lib/mkcmd'
