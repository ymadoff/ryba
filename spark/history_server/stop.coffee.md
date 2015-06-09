# Spark History Web UI Stop

    module.exports = []
    module.exports.push require('./index').configure

    module.exports.push name: 'Spark History Server # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd:  """
        /usr/hdp/current/spark-historyserver/sbin/stop-server.sh
        """
      .then next
