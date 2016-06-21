
# Spark History Server Status
  
    module.exports = header: 'Spark History Server Status', label_true: 'STARTED', label_false: "STOPPED", handler: ->
      @service_status
        name: 'spark-history-server'
        if_exist: '/etc/init.d/spark-history-server'
