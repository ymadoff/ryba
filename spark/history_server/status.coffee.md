# Apache Spark History Server

  Check 

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

    module.exports.push name: 'Spark History Server # STATUS', timeout: -1, label_true: 'RUNNING', label_false: "STOPPED", handler: (ctx, next) ->
      {spark} = ctx.config.ryba
      ctx
        .child().execute
              cmd:  """
                    curl -s -o /dev/null -w'%{http_code}' --negotiate -u: -k http://"#{spark.history_server.fqdn}:#{spark.history_server.port}"
                    """
      , (err, executed, stdout, stderr) ->
        return err if err
        if  stdout == "200"
          next err, true
        else
          next err, false
        