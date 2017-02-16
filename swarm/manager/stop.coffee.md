
# Stop Docker Swarm Manager Container
Stop the docker container using docker stop command.

    module.exports = header: 'Swarm Manager Stop', handler: ->
      @docker.stop
        docker: @config.docker
        container: @config.ryba.swarm.manager.name
      
