
# OpenTSDB Check

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Check HDFS

    module.exports.push header: 'OpenTSDB # Check HTTP', label_true: 'CHECKED', handler: ->
      {opentsdb} = @config.ryba
      @execute cmd: "curl http://#{@config.host}:#{opentsdb.config['tsd.network.port']}"

## Dependencies
