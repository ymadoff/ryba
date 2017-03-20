
# ActiveMQ Server Check

    module.exports =  header: 'ActiveMQ Server Check', label_true: 'CHECKED', handler: ->
      @connection.wait
        host: @config.host
        port: 8161
