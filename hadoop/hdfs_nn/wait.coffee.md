
# Hadoop HDFS NameNode Wait

    module.exports = header: 'HDFS NN Wait', timeout: -1, label_true: 'READY', handler:  ->
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'

## Wait HTTP ports

      @connection.wait
        header: 'HTTP'
        servers: for nn_ctx in nn_ctxs
          {nameservice} = nn_ctx.config.ryba
          protocol = if nn_ctx.config.ryba.hdfs.nn.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
          nameservice = if nn_ctxs.length > 1 then ".#{nameservice}" else ''
          shortname = if nn_ctxs.length > 1 then ".#{nn_ctx.config.shortname}" else ''
          port = nn_ctx.config.ryba.hdfs.nn.site["dfs.namenode.#{protocol}-address#{nameservice}#{shortname}"].split(':')[1]
          host: nn_ctx.config.host, port: port

## Wait Safemode

Wait for HDFS safemode to exit. It is not enough to start the NameNodes but the
majority of DataNodes also need to be running.

      # TODO: there are much better solutions, for exemple
      # if 'ryba/hadoop/hdfs_client', then `hdfs dfsadmin`
      # else use curl
      {hdfs, hadoop_conf_dir} = @config.ryba
      if @has_service 'ryba/hadoop/hdfs_nn' then conf_dir = "#{hdfs.nn.conf_dir}"
      else if @has_service 'ryba/hadoop/hdfs_dn' then conf_dir = "#{hdfs.dn.conf_dir}"
      else if @has_service 'ryba/hadoop/hdfs_snn' then conf_dir = "#{hdfs.snn.conf_dir}"
      else if @has_service 'ryba/hadoop/hdfs_client' then conf_dir = "#{hadoop_conf_dir}"
      else throw Error 'Invalid configuration'
      @wait_execute
        header: 'Safemode'
        cmd: mkcmd.hdfs @, "hdfs --config '#{conf_dir}' dfsadmin -safemode get | grep OFF"
        interval: 3000

## Dependencies

    mkcmd = require '../../lib/mkcmd'
