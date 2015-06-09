# Spark History Server


    module.exports = []

## Spark Configuration

    module.exports.configure = (ctx) ->
      {realm} = ctx.config.ryba
      spark.kr5_user ?= {}
      spark.kr5_user.principal ?= "spark/#{ctx.config.host}@#{realm}"
      spark.krb5_user.keytab ?= '/etc/security/keytabs/spark.keytab'
      spark.history_server ?= {}
      spark.history_server.port = '8190'


    module.exports.push commands: 'check', modules: 'ryba/spark/history_server/check'

    module.exports.push commands: 'install', modules: [
      'ryba/spark/history_server/install'
      'ryba/spark/history_server/check'
    ]

    module.exports.push commands: 'status', modules: 'ryba/spark/history_server/status'

    module.exports.push commands: 'start', modules: 'ryba/spark/history_server/start'

    module.exports.push commands: 'stop', modules: 'ryba/spark/history_server/stop'
