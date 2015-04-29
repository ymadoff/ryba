
# Hadoop HDFS SecondaryNameNode 

    module.exports = []

## Configuration

    module.exports.configure = (ctx) ->
      require('../hdfs').configure ctx
      {ryba} = ctx.config
      # Store the temporary images to merge
      ryba.hdfs.site['dfs.namenode.checkpoint.dir'] ?= ['/var/hdfs/checkpoint']
      ryba.hdfs.site['dfs.namenode.checkpoint.dir'] = ryba.hdfs.site['dfs.namenode.checkpoint.dir'].join ',' if Array.isArray ryba.hdfs.site['dfs.namenode.checkpoint.dir']
      # Network
      ryba.hdfs.site['dfs.namenode.secondary.http-address'] ?= "#{secondary_namenode}:50090"
      # Kerberos principal name for the secondary NameNode.
      ryba.hdfs.site['dfs.secondary.namenode.kerberos.principal'] ?= "nn/#{ryba.static_host}@#{ryba.realm}"
      # Combined keytab file containing the NameNode service and host principals.
      ryba.hdfs.site['dfs.secondary.namenode.keytab.file'] ?= '/etc/security/keytabs/nn.service.keytab'
      # Address of secondary namenode web server
      ryba.hdfs.site['dfs.secondary.http.address'] ?= "#{ctx.config.host}:50090"
      # The https port where secondary-namenode binds
      ryba.hdfs.site['dfs.secondary.https.port'] ?= '50490' # todo, this has nothing to do here
      ryba.hdfs.site['dfs.namenode.secondary.http-address'] ?= "#{ctx.config.host}:50090" # HDS > 2.5.1
      ryba.hdfs.site['dfs.namenode.secondary.https-address'] ?= "#{ctx.config.host}:50490" # HDS > 2.5.1
      ryba.hdfs.site['dfs.secondary.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/#{ryba.static_host}@#{ryba.realm}"
      ryba.hdfs.site['dfs.secondary.namenode.kerberos.https.principal'] = "HTTP/#{ryba.static_host}@#{ryba.realm}"

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/hadoop/hdfs_snn/backup'

    # module.exports.push commands: 'check', modules: 'ryba/hadoop/hdfs_snn_check'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/hdfs_snn/install'
      'ryba/hadoop/hdfs_snn/start'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hadoop/hdfs_snn/start'

    # module.exports.push commands: 'status', modules: 'ryba/hadoop/hdfs_snn_status'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/hdfs_snn/stop'



