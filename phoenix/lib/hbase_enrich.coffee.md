
# Enrich and restart HBase

    module.exports = (options) ->
      {hbase} = @config.ryba
      # @execute
      #   header: 'HBase Master: Phoenix: Link JAR'
      #   cmd:"""
      #   PKG=`rpm --queryformat "/usr/hdp/current/phoenix-client/lib/phoenix-core-%{VERSION}-%{RELEASE}" -q phoenix`;
      #   PKG=${PKG/el*/jar};
      #   ln -sf $PKG /usr/hdp/current/hbase-client/lib/phoenix.jar
      #   """
      #   unless_exists: '/usr/hdp/current/hbase-client/lib/phoenix.jar'
      # @hconfigure
      #   header: 'HBase Master: Phoenix: Configure HBase'
      #   destination: "#{hbase.conf_dir}/hbase-site.xml"
      #   properties: hbase.site
      #   merge: true
      #   uid: hbase.user.name
      #   gid: hbase.group.name
      #   backup: true
      @service
        header: 'HBase Master: Phoenix: Restart Master'
        srv_name: "hbase-master"
        action: 'restart'
        if: [
          @has_module 'ryba/hbase/master'
          -> @status()
        ]
      @service
        header: 'HBase Master: Phoenix: Restart RegionServer'
        srv_name: "hbase-regionserver"
        action: 'restart'
        if: [
          @has_module 'ryba/hbase/regionserver'
          -> @status()
        ]
        
    module.exports.register = (options) ->
      @register 'hbase_enrich', module.exports unless @registered 'hbase_enrich'
