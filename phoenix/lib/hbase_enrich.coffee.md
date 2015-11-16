
# Enrich and restart HBase

    module.exports = (options) ->
      {hbase} = @config.ryba
      @execute
        cmd:"""
        PKG=`rpm --queryformat "/usr/hdp/current/phoenix-client/lib/phoenix-core-%{VERSION}-%{RELEASE}" -q phoenix`;
        PKG=${PKG/el*/jar};
        ln -sf $PKG /usr/hdp/current/hbase-client/lib/phoenix.jar
        """
        unless_exists: '/usr/hdp/current/hbase-client/lib/phoenix.jar'
      @hconfigure
        destination: "#{hbase.conf_dir}/hbase-site.xml"
        properties: hbase.site
        merge: true
        uid: hbase.user.name
        gid: hbase.group.name
        backup: true
      @service
        srv_name: "hbase-master"
        action: 'restart'
        if: [
          @has_module 'ryba/hbase/master'
          -> @status -1
        ]
      @service
        srv_name: "hbase-regionserver"
        action: 'restart'
        if: [
          @has_module 'ryba/hbase/regionserver'
          -> @status -2
        ]
        
    module.exports.register = (options) ->
      @register 'hbase_enrich', module.exports unless @registered 'hbase_enrich'
