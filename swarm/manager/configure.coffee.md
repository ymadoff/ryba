
# Configure Swarm Manager hosts

Use the `ryba.swarm_primary` for setting which host should be the primary swarm manager.
This host will be used when rendering default DOCKER_HOST ENV variable on swarm nodes.

    module.exports = ->
      zoo_ctxs = @contexts('ryba/zookeeper/server').filter (ctx) ->
        ctx.config.ryba.zookeeper.config['peerType'] is 'participant'
      docker = @config.docker ?= {}
      ryba = @config.ryba ?= {}
      ryba.swarm_primary ?= @contexts('ryba/swarm/manager')[0].config.host is @config.host
      swarm = ryba.swarm ?= {}
      swarm.image ?= 'swarm'
      swarm.tag ?= 'latest'
      swarm.conf_dir ?= '/etc/docker-swarm'

## Service Discovery
Configures the docker daemon engine start options for swarm.
For now only zookeeper is supported for discovery backend.

Note: The listen address and advertise adress are different:
  - the advertise address configures which address CLI should use to communicate
with the swarm manager's docker engine
  - the listen address configures the docker engine to listen to all interfaces of the machine.

      swarm.cluster ?= {}
      swarm.cluster.discovery ?= 'zookeeper'
      swarm.manager ?= {}
      swarm.manager.name ?= 'swarm_manager'
      swarm.manager.advertise_host ?= @config.ip
      swarm.manager.advertise_port ?= @config.docker.default_port
      swarm.manager.listen_host ?= '0.0.0.0'
      swarm.manager.listen_port ?= 3376
      switch swarm.cluster.discovery
        when 'zookeeper'
          swarm.cluster.zk_node ?= '/swarm-nodes'
          swarm.cluster.zk_urls ?= zoo_ctxs
            .filter( (ctx) -> ctx.config.ryba.zookeeper.config['peerType'] is 'participant')
            .map( (ctx) -> "#{ctx.config.host}:#{ctx.config.ryba.zookeeper.port}").join ','
          swarm.cluster.zk_store ?= "zk://#{swarm.cluster.zk_urls}#{swarm.cluster.zk_node}"
        else
          throw Error "Ryba does not support service discovery backend #{swarm.cluster.discovery} for swarm"

## Docker Deamon Configuration
Pass docker start option to docker daemon to use it with swarm.

### TCP Socket
Swarm manager uses the advertise address to communicate. It must be specified
in the start option of the local daemon engine to enable it.

      tcp_socket = "#{@config.host}:#{swarm.manager.advertise_port}"
      if @config.docker.sockets.tcp.indexOf(tcp_socket) is -1
      then @config.docker.sockets.tcp.push tcp_socket
      
### Swarm Cluster
This starting options should be injected to @config.docker variable. For now 
`ryba/swarm/manager` modify the starting options and restart docker engine.

      # @config.docker.other_args['cluster-store'] ?= swarm.cluster.zk_store
      # @config.docker.other_args['cluster-advertise'] ?= "#{swarm.manager.advertise_host}:#{swarm.manager.advertise_port}"
      swarm.other_args ?= []
      swarm.other_args['cluster-store'] ?= swarm.cluster.zk_store
      swarm.other_args['cluster-advertise'] ?= "#{swarm.manager.advertise_host}:#{swarm.manager.advertise_port}"
      swarm.other_args = merge  swarm.other_args, @config.docker.other_args

## Dependencies

    {merge} = require 'mecano/lib/misc'
