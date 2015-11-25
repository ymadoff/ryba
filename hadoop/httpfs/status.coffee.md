
# HDFS HttpFS Status

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Status

Check if HTTPFS is running. The process ID is located by default
inside "/var/run/httpfs/httpfs.pid".

    module.exports.push header: 'HDFS HttpFS # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @execute
        cmd: 'service hadoop-httpfs status'
        code_skipped: 3
        if_exists: '/etc/init.d/hadoop-httpfs'
