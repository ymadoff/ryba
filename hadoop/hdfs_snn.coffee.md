
# Hadoop HDFS SecondaryNameNode 

    module.exports = []

## Configuration

    module.exports.configure = (ctx) ->
      require('./hdfs').configure ctx
      {hdfs_site, static_host, realm} = ctx.config.ryba
      # Store the temporary images to merge
      hdfs_site['dfs.namenode.checkpoint.dir'] ?= ['/var/hdfs/checkpoint']
      hdfs_site['dfs.namenode.checkpoint.dir'] = hdfs_site['dfs.namenode.checkpoint.dir'].join ',' if Array.isArray hdfs_site['dfs.namenode.checkpoint.dir']
      # Kerberos principal name for the secondary NameNode.
      hdfs_site['dfs.secondary.namenode.kerberos.principal'] ?= "nn/#{static_host}@#{realm}"
      # Combined keytab file containing the NameNode service and host principals.
      hdfs_site['dfs.secondary.namenode.keytab.file'] ?= '/etc/security/keytabs/nn.service.keytab'
      # Address of secondary namenode web server
      hdfs_site['dfs.secondary.http.address'] ?= "#{ctx.config.host}:50090"
      # The https port where secondary-namenode binds
      hdfs_site['dfs.secondary.https.port'] ?= '50490' # todo, this has nothing to do here
      hdfs_site['dfs.namenode.secondary.http-address'] ?= "#{ctx.config.host}:50090" # HDS > 2.5.1
      hdfs_site['dfs.namenode.secondary.https-address'] ?= "#{ctx.config.host}:50490" # HDS > 2.5.1
      hdfs_site['dfs.secondary.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/#{static_host}@#{realm}"
      hdfs_site['dfs.secondary.namenode.kerberos.https.principal'] = "HTTP/#{static_host}@#{realm}"

    # module.exports.push commands: 'backup', modules: 'ryba/hadoop/hdfs_snn_backup'

    # module.exports.push commands: 'check', modules: 'ryba/hadoop/hdfs_snn_check'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/hdfs_snn_install'
      'ryba/hadoop/hdfs_snn_start'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hadoop/hdfs_snn_start'

    # module.exports.push commands: 'status', modules: 'ryba/hadoop/hdfs_snn_status'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/hdfs_snn_stop'



