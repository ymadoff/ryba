# Spark History Web UI Stop

    module.exports = []
    module.exports.push require('./index').configure

    module.exports.push name: 'Spark History Server # Stop', timeout: -1, label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd:  """
          /usr/hdp/current/spark-historyserver/sbin/stop-server.sh 
        """
      , (err, executed) ->
      return next executed 