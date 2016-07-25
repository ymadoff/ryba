
# Spark History Server Check

    module.exports = header: 'Spark History Server Check', label_true: 'CHECKED', handler: ->
      {spark} = @config.ryba

      @call  'ryba/spark/history_server/wait'

      # TODO Juin 2016: get https protocol when available (from 2.0 version)
      @call
        handler: (_, callback )->
          url = "http://#{spark.history.conf['spark.yarn.historyServer.address']}/api/v1/applications"
          @execute
            cmd: "curl #{url}"
          , (err, _, stdout) ->
            return callback err if err
            try
              stdout = stdout.trim()
              results = JSON.parse stdout
              return callback null, true if results
            catch err
              return callback err





