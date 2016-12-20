
# HDFS HttpFS Status

Check if HTTPFS is running. The process ID is located by default
inside "/var/run/httpfs/httpfs.pid".

    module.exports = header: 'HDFS HttpFS Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        name: 'hadoop-httpfs'
