
# Spark History Server Status

  Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

    module.exports.push name: 'Spark HS # Status', label_true: 'STARTED', label_false: "STOPPED", handler: (ctx, next) ->
      {spark} = ctx.config.ryba
      ctx
      .execute
        cmd:  """
        curl -s -o /dev/null -w'%{http_code}' --negotiate -u: http://"#{ctx.config.host}:#{spark.history_server.port}"
        """
      , (err, executed, stdout, stderr) ->
        return next err, stdout is '200'
