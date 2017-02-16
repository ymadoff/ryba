
# Start Docker Swarm Agent Container
Start the docker container using docker start commande.

    module.exports = header: 'Swarm Agent Start', handler: ->
      @call 'ryba/zookeeper/server/wait'
      @connection.wait
        header: 'Wait Manager'
        servers: for ctx in @contexts('ryba/swarm/manager')
          host: ctx.config.host
          port: ctx.config.ryba.swarm.manager.advertise_port
      @docker.start
        docker: @config.docker
        container: @config.ryba.swarm.agent.name
      
