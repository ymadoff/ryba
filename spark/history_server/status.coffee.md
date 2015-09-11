
# Spark History Server Status

  Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

    module.exports.push name: 'Spark HS # Status', label_true: 'STARTED', label_false: "STOPPED", handler: ->
      {spark} = @config.ryba
      @execute
        cmd:  """
        out=`curl -s -o /dev/null -w'%{http_code}' --negotiate -u: http://"#{ctx.config.host}:#{spark.history_server.port}"`
        [ $out == '200' ]
        """
