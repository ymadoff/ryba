
# Hadoop HDFS NameNode Wait

Single Namenode without Kerberos:

```json
{
  "conf_dir": "/etc/hadoop-hdfs-namenode/conf",
  "hdfs_user": { "name": "hdfs" },
  "http": { "host": "master1.ryba", "port": 50470 }
}
```

HA Namenodes with Kerberos:

```json
{
  "conf_dir": "/etc/hadoop-hdfs-namenode/conf",
  "hdfs_user": { "principal": "hdfs@HADOOP.RYBA", "password": "hdfs123" },
  "http": [
    { "host": "master1.ryba", "port": 50470 },
    { "host": "master2.ryba", "port": 50470 }
  ]
}
```

    module.exports = header: 'HDFS NN Wait', timeout: -1, label_true: 'READY', handler:  ->
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
      {hdfs, hadoop_conf_dir} = @config.ryba
      if @has_service 'ryba/hadoop/hdfs_nn' then conf_dir = "#{hdfs.nn.conf_dir}"
      else if @has_service 'ryba/hadoop/hdfs_dn' then conf_dir = "#{hdfs.dn.conf_dir}"
      else if @has_service 'ryba/hadoop/hdfs_snn' then conf_dir = "#{hdfs.snn.conf_dir}"
      else if @has_service 'ryba/hadoop/hdfs_client' then conf_dir = "#{hadoop_conf_dir}"
      else throw Error 'Invalid configuration'
      options = {}
      options.conf_dir = conf_dir
      options.hdfs_user = hdfs.krb5_user
      options.wait_ipc = for nn_ctx in nn_ctxs
        {nameservice} = nn_ctx.config.ryba
        nameservice = if nn_ctxs.length > 1 then ".#{nameservice}" else ''
        shortname = if nn_ctxs.length > 1 then ".#{nn_ctx.config.shortname}" else ''
        nn_ctx.config.ryba.hdfs.nn.site["dfs.namenode.rpc-address#{nameservice}#{shortname}"].split(':')
        host: fqdn, port: port
      options.wait_http = for nn_ctx in nn_ctxs
        {nameservice} = nn_ctx.config.ryba
        protocol = if nn_ctx.config.ryba.hdfs.nn.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
        nameservice = if nn_ctxs.length > 1 then ".#{nameservice}" else ''
        shortname = if nn_ctxs.length > 1 then ".#{nn_ctx.config.shortname}" else ''
        [fqdn, port] = nn_ctx.config.ryba.hdfs.nn.site["dfs.namenode.#{protocol}-address#{nameservice}#{shortname}"].split(':')
        host: fqdn, port: port

## Wait IPC Ports

Port is defined in the "dfs.namenode.rpc-address" property of hdfs-site. The default
value is 8020.

      @connection.wait
        header: 'IPC'
        servers: options.wait_ipc

## Wait HTTP ports

      @connection.wait
        header: 'HTTP'
        servers: options.wait_http

## Wait Safemode

Wait for HDFS safemode to exit. It is not enough to start the NameNodes but the
majority of DataNodes also need to be running.

      # TODO: there are much better solutions, for exemple
      # if 'ryba/hadoop/hdfs_client', then `hdfs dfsadmin`
      # else use curl
      @wait.execute
        header: 'Safemode'
        cmd: mkcmd hdfs.krb5_user, "hdfs --config '#{options.conf_dir}' dfsadmin -safemode get | grep OFF"
        interval: 3000

## Dependencies

    mkcmd = require '../../lib/mkcmd'
