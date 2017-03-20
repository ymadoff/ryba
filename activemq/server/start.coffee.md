
# ActiveMQ Server Start

ActiveMQ Server is started through service command.Which is wrapper around 
the docker container.

    module.exports = header: 'ActiveMQ Server Start', label_true: 'STARTED', handler: ->
      @service.start
        name: 'activemq'
