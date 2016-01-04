
# OpenTSDB Check

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Check HTTP

    module.exports.push header: 'OpenTSDB # Check HTTP', label_true: 'CHECKED', handler: ->
      {opentsdb} = @config.ryba
      @execute cmd: "curl http://#{@config.host}:#{opentsdb.config['tsd.network.port']}"

## Check HTTP API

    module.exports.push header: 'OpenTSDB # Check HTTP API', label_true: 'CHECKED', handler: (_, callback) ->
      {opentsdb} = @config.ryba
      date = Date.now()
      put =
        metric: 'ryba.test'
        timestamp: date
        value: 42
        tags: api: 'http', host: @config.host
      get =
        start: date
        queries: [
          aggregator: 'count'
          metric: 'ryba.test'
          tags: api: 'http', host: @config.host
        ]
      @
      .execute 
        cmd: """
        curl --fail -X POST -d '#{JSON.stringify put}' http://#{@config.host}:#{opentsdb.config['tsd.network.port']}/api/put
        """
      # Waiting 2 secs. Opentsdb is not consistent
      .execute
        cmd: """
        sleep 2;
        curl --fail -X POST -d '#{JSON.stringify get}' http://#{@config.host}:#{opentsdb.config['tsd.network.port']}/api/query
        """
      , (err, executed, stdout, stderr) ->
        [result] = JSON.parse stdout
        throw Error "New key 'ryba.test' not found" unless Object.keys(result.dps).length > 0
      .then callback

## Dependencies
