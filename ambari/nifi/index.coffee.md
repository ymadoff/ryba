
# Nifi with Ambari

    module.exports =
      use:
        ssl: implicit: true, module: 'masson/core/ssl'
        ambari: 'ryba/ambari/agent'
      configure: 'ryba/ambari/nifi/configure'
      commands:
        'prepare': ->
          options = @config.ambari_nifi
          active = @contexts('ryba/ambari/nifi')[0]?.config.host is @config.host
          @call 'ryba/ambari/nifi/prepare', if: active, options
        'install': ->
          options = @config.ambari_nifi
          @call 'ryba/ambari/nifi/install', options
