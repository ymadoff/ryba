
# OpenTSDB Check

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Check HDFS

    module.exports.push header: 'OpenTSDB # Check', timeout: -1, label_true: 'CHECKED', handler: ->
      {opentsdb} = @config.ryba

## Dependencies
