
# Ambari Server Prepare

Online operation required to install an Ambari Server.

    module.exports = header: 'Ambari Server Prepare', ssh: null, handler: ->
      options = @config.ryba.ambari_server
      for name, mpack of options.mpacks
        @file.cache
          header: "Mpack #{name}"
          if: mpack.enabled
          location: true
          md5: mpack.md5
          sha256: mpack.sha256
        , "#{mpack.source}"
