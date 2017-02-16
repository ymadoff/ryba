
# Docker Swarm Agent

    module.exports = 
      use:
        docker: implicit:true, module: 'masson/commons/docker'
        zookeeper: module: 'ryba/zookeeper/server'
        swarm_manager: module: 'ryba/swarm/manager'
      configure:
        'ryba/swarm/agent/configure'
      commands:
        install: [
          'ryba/swarm/agent/install'
          'ryba/swarm/agent/start'
        ]
        start: 'ryba/swarm/agent/start'
        stop: 'ryba/swarm/agent/stop'
