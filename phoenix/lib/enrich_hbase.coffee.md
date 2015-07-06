
# Enrich and restart HBase

    module.exports = (ctx) ->
      return if ctx.registered 'phoenix_enrich_hbase'
      ctx.register 'phoenix_enrich_hbase', (options, callback) ->
        {hbase} = ctx.config.ryba
        ctx.execute
          cmd:"""
          PKG=`rpm --queryformat "/usr/hdp/current/phoenix-client/lib/phoenix-core-%{VERSION}-%{RELEASE}" -q phoenix`;
          PKG=${PKG/el*/jar};
          ln -sf $PKG /usr/hdp/current/hbase-client/lib/phoenix.jar
          """
          not_if_exists: '/usr/hdp/current/hbase-client/lib/phoenix.jar'
        .hconfigure
          destination: "#{hbase.conf_dir}/hbase-site.xml"
          # default: "#{__dirname}/../../resources/hbase/hbase-site.xml"
          # local_default: true
          properties: hbase.site
          merge: true
          uid: hbase.user.name
          gid: hbase.group.name
          backup: true
        .then (err, status) ->
          return callback err if err or not status
          ctx
          .execute
            srv_name: "hbase-master"
            action: 'restart'
          .service
            srv_name: "hbase-regionserver"
            action: 'restart'
          .then (err) -> callback err, true