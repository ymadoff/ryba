# Spark History Web UI Start

    module.exports = []
    module.exports.push require('./index').configure

    module.exports.push name: 'Spark History Server # Start', timeout: -1, label_true: 'STARTED', handler: (ctx, next) ->
      ctx.execute
        cmd:  """
            /usr/hdp/current/spark-historyserver/sbin/start-server.sh 
        """
      , next

