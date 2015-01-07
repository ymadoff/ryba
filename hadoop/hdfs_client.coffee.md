
# Hadoop HDFS Client

    module.exports = []

    module.exports.configure = (ctx) ->
      require('./hdfs').configure ctx
      {ryba} = ctx.config
      ryba.hdfs_site['dfs.domain.socket.path'] ?= '/var/lib/hadoop-hdfs/dn_socket'
      ryba.hdfs_site['dfs.namenode.kerberos.principal'] ?= "nn/#{ryba.static_host}@#{ryba.realm}"

    module.exports.push commands: 'check', modules: 'ryba/hadoop/hdfs_client_check'

    module.exports.push commands: 'install', modules: 'ryba/hadoop/hdfs_client_install'
