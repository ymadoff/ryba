# Spark History Web UI Start

    module.exports = []
    module.exports.push require('./index').configure

    module.exports.push name: 'Spark HS # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.execute
        cmd:  """
        /usr/hdp/current/spark-historyserver/sbin/start-server.sh
        """
      .then next
