
# Ambari Nifi Prepare

    module.exports = header: 'Ambari Nifi Prepare', ssh: null, handler: (options) ->
      @file.cache
        header: "Toolkit"
        location: true
        md5: options.toolkit.md5
        sha256: options.toolkit.sha256
      , "#{options.toolkit.source}"
