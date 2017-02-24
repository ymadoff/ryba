
# Hadoop HDFS SecondaryNameNode 

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        hadoop_core: implicit: true, module: 'ryba/hadoop/core'
    configure: ->
      {ryba} = ctx.config
      hdfs = ryba.hdfs ?= {}
      hdfs.snn ?= {}
      hdfs.snn.conf_dir ?= '/etc/hadoop-hdfs-secondarynamenode/conf'
      # Store the temporary images to merge
      hdfs.site['dfs.namenode.checkpoint.dir'] ?= ['file:///var/hdfs/checkpoint']
      hdfs.site['dfs.namenode.checkpoint.dir'] = hdfs.site['dfs.namenode.checkpoint.dir'].join ',' if Array.isArray hdfs.site['dfs.namenode.checkpoint.dir']
      hdfs.site['dfs.namenode.checkpoint.edits.dir'] ?= '${dfs.namenode.checkpoint.dir}' # HDP invalid default value
      # Network
      hdfs.site['dfs.namenode.secondary.http-address'] ?= "#{ctx.config.host}:50090"
      # Kerberos principal name for the secondary NameNode.
      hdfs.site['dfs.secondary.namenode.kerberos.principal'] ?= "nn/_HOST@#{ryba.realm}"
      # Combined keytab file containing the NameNode service and host principals.
      hdfs.site['dfs.secondary.namenode.keytab.file'] ?= '/etc/security/keytabs/nn.service.keytab'
      # Address of secondary namenode web server
      hdfs.site['dfs.secondary.http.address'] ?= "#{ctx.config.host}:50090"
      # The https port where secondary-namenode binds
      hdfs.site['dfs.secondary.https.port'] ?= '50490' # todo, this has nothing to do here
      hdfs.site['dfs.namenode.secondary.http-address'] ?= "#{ctx.config.host}:50090"
      hdfs.site['dfs.namenode.secondary.https-address'] ?= "#{ctx.config.host}:50490"
      hdfs.site['dfs.secondary.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/_HOST@#{ryba.realm}"
      hdfs.site['dfs.secondary.namenode.kerberos.https.principal'] = "HTTP/_HOST@#{ryba.realm}"
    commands:
      # 'backup':
      #   'ryba/hadoop/hdfs_snn/backup'
      # 'check':
      #   'ryba/hadoop/hdfs_snn_check'
      'install': [
        'ryba/hadoop/hdfs_snn/install'
        'ryba/hadoop/hdfs_snn/start'
      ]
    'start':
      'ryba/hadoop/hdfs_snn/start'
    'status':
      'ryba/hadoop/hdfs_snn/status'
    'stop':
      'ryba/hadoop/hdfs_snn/stop'
