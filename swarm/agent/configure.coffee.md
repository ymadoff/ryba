
# Configure Swarm Manager hosts

    module.exports = ->
      docker = @config.docker ?= {}
      ryba = @config.ryba ?= {}
      [primary_ctx] = @contexts('ryba/swarm/manager').filter( (ctx) -> ctx.config.ryba.swarm_primary  is true )
      throw Error 'No Swarm Manager is configured' unless primary_ctx?
      swarm = ryba.swarm ?= {}
      swarm.image ?= 'swarm'
      swarm.tag ?= 'latest'
      swarm.conf_dir ?= '/etc/docker-swarm'

## Read From Manager

      swarm.cluster ?= {}
      swarm.cluster =  merge primary_ctx.config.ryba.swarm.cluster, swarm.cluster
      swarm.agent ?= {}
      swarm.agent.name ?= 'swarm_agent'
      #Note for docker to be able to start the ip address must be set (instead of hostname)
      swarm.agent.advertise_host ?= @config.host
      swarm.agent.advertise_port ?= @config.docker.default_port

## Docker Deamon Configuration
Pass docker start option to docker daemon to use it with swarm.

### TCP Socket
Swarm nodes use the advertise address to communicate. It must be specified
in the start option of the local daemon engine to enable it.

      tcp_socket = "#{@config.host}:#{swarm.agent.advertise_port}"
      if @config.docker.sockets.tcp.indexOf(tcp_socket) is -1
      then @config.docker.sockets.tcp.push tcp_socket
other_args      @config.docker.
      
      
### Swarm Cluster
This starting options should be injected to @config.docker variable. For now 
`ryba/swarm/agent` modify the starting options and restart docker engine.

      # @config.docker.other_args['cluster-store'] ?= swarm.cluster.zk_store
      # @config.docker.other_args['cluster-advertise'] ?= "#{swarm.manager.advertise_host}:#{swarm.manager.advertise_port}"
      swarm.other_args ?= []
      swarm.other_args['cluster-store'] ?= swarm.cluster.zk_store
      swarm.other_args['cluster-advertise'] ?= "#{@config.ip}:#{swarm.agent.advertise_port}"
      @config.docker.other_args = merge @config.docker.other_args, swarm.other_args

## Dependencies

    {merge} = require 'nikita/lib/misc'
