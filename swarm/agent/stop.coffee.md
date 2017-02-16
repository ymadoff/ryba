
# Stop Docker Swarm Agent Container
Stop the docker container using docker stop commande.

    module.exports = header: 'Swarm Agent Stop', handler: ->
      @docker.stop
        docker: @config.docker
        container: @config.ryba.swarm.agent.name
      
