
# MongoDB Routing Server Start

Waits the replica set of config server to be initialized and ready before starting any mongos instance.
For this we wait to be able to execute a rs.status() on  the first initiated
replica set primary server.

    module.exports = header: 'MongoDB Router Server Start', label_true: 'READY', timeout: -1, handler: ->
      mongodb_configsrvs = @contexts 'ryba/mongodb/configsrv'
      {mongodb, realm, ssl} = @config.ryba
      {router} = mongodb
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      mongo_shell_exec =  ""
      mongo_shell_admin_exec =  "#{mongo_shell_exec} -u #{mongodb.admin.name} --password  '#{mongodb.admin.password}'"
      # find master of the config server's replica set
      [replica_master_ctx] = mongodb_configsrvs.filter (ctx) =>
        configsrv = ctx.config.ryba.mongodb.configsrv
        configsrv.config.replication.replSetName is router.my_cfgsrv_repl_set and configsrv.is_master
      # we wait for the replica set to be ready before starting the router server
      mongo_shell_root_exec =  "mongo admin "
      mongo_shell_root_exec +=  "-h #{replica_master_ctx.config.host} "
      mongo_shell_root_exec += "--port #{replica_master_ctx.config.ryba.mongodb.configsrv.config.net.port} "
      mongo_shell_root_exec += "-u #{replica_master_ctx.config.ryba.mongodb.root.name} "
      mongo_shell_root_exec += "-p #{replica_master_ctx.config.ryba.mongodb.root.password} "
      cmd = " --eval 'rs.status().ok ' | grep -v 'MongoDB shell version' | grep -v 'connecting to:' | grep 1 "
      @wait_execute
        cmd: "#{mongo_shell_root_exec} #{cmd}"
      # TODO check if all config server are available
      @service.start name: 'mongod-router-server'
