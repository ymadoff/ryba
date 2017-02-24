
# Phoenix Install

Please refer to the Hortonworks [documentation][phoenix-doc].

    module.exports =  header: 'Phoenix Client Install', handler: ->
      {hadoop_conf_dir, phoenix} = @config.ryba
      {hbase} = @config.ryba

## Register

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Packages

      @service name: 'phoenix'
      @hdp_select name: 'phoenix-client'

      @execute
        header: 'Hadoop Configuration'
        cmd:"""
        ln -sf #{hadoop_conf_dir}/core-site.xml /usr/hdp/current/phoenix-client/bin/core-site.xml
        """
        unless_exists: '/usr/hdp/current/phoenix-client/bin/core-site.xml'

      @execute
        header: 'HBase Configuration'
        cmd:"""
        ln -sf #{hadoop_conf_dir}/hbase-site.xml /usr/hdp/current/phoenix-client/bin/hbase-site.xml
        """
        unless_exists: '/usr/hdp/current/phoenix-client/bin/hbase-site.xml'

[phoenix-doc]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.4/HDP_Man_Install_v224/index.html#installing_phoenix
