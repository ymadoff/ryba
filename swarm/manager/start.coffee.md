
# Start Docker Swarm Manager Container
Start the docker container using docker start commande.

    module.exports = header: 'Swarm Manager Start', handler: ->
      @call 'ryba/zookeeper/server/wait'
      @docker.start
        docker: @config.docker
        container: @config.ryba.swarm.manager.name
      
