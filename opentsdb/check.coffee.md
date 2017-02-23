
# OpenTSDB Check

    module.exports = header: 'OpenTSDB Check', label_true: 'CHECKED', handler: ->
      {opentsdb} = @config.ryba

## Check HTTP

      @system.execute 
        header: 'Check HTTP'
        label_true: 'CHECKED'
        cmd: "curl http://#{@config.host}:#{opentsdb.config['tsd.network.port']}"

## Check HTTP API

      @call header: 'Check HTTP API', label_true: 'CHECKED', handler: (_, callback) ->
        date = Date.now()
        put = JSON.stringify
          metric: 'ryba.test'
          timestamp: date
          value: 42
          tags: api: 'http', host: @config.host
        get = JSON.stringify
          start: date-100
          # set end time manually to not have the opentsdb'server default time
          end: date+100
          queries: [
            aggregator: 'count'
            metric: 'ryba.test'
            tags: api: 'http', host: @config.host
          ]
        @system.execute 
          cmd: """
          curl --fail -X POST -d '#{put}' http://#{@config.host}:#{opentsdb.config['tsd.network.port']}/api/put
          """
        @system.execute
          # Waiting 2 secs. Opentsdb is not consistent
          cmd: """
          sleep 2;
          curl --fail -X POST -d '#{get}' http://#{@config.host}:#{opentsdb.config['tsd.network.port']}/api/query
          """
        , (err, executed, stdout, stderr) ->
          [result] = JSON.parse stdout
          throw Error "New key 'ryba.test' not found" unless Object.keys(result.dps).length > 0
        @then callback
