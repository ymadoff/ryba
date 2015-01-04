
# HDFS NameNode Check

Check the health of the NameNode(s).

In HA mode, we need to ensure both NameNodes are installed before testing SSH
Fencing. Otherwise, a race condition may occur if a host attempt to connect
through SSH over another one where the public key isn't yet deployed.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_nn_wait'
    module.exports.push require('./hdfs').configure

## Check HTTP

    module.exports.push name: 'Hadoop HDFS NN # Check HTTP', timeout: -1, label_true: 'CHECKED', callback: (ctx, next) ->
      {hdfs_site, active_nn_host} = ctx.config.ryba
      is_ha = ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      state = if not is_ha or active_nn_host is ctx.config.host then 'active' else 'standby'
      protocol = if hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      nameservice = if is_ha then ".#{ctx.config.ryba.hdfs_site['dfs.nameservices']}" else ''
      shortname = if is_ha then ".#{ctx.config.shortname}" else ''
      address = hdfs_site["dfs.namenode.#{protocol}-address#{nameservice}#{shortname}"]
      securityEnabled = protocol is 'https'
      ctx.execute
        cmd: mkcmd.hdfs ctx, "curl --negotiate -k -u : #{protocol}://#{address}/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus"
      , (err, executed, stdout) ->
        return next err if err
        try
          data = JSON.parse stdout
          return next Error "Invalid Response" unless /^Hadoop:service=NameNode,name=NameNodeStatus$/.test data?.beans[0]?.name
          return next Error "WARNING: Invalid security (#{data.beans[0].SecurityEnabled}, instead of #{securityEnabled}" unless data.beans[0].SecurityEnabled is securityEnabled
          return next null, "WARNING: Invalid state (#{data.beans[0].State} instead of #{state})" unless data.beans[0].State is state
          next null, true
        catch err then return next err

## Check Health

Connect to the provided NameNode to check its health. The NameNode is capable of
performing some diagnostics on itself, including checking if internal services
are running as expected. This command will return 0 if the NameNode is healthy,
non-zero otherwise. One might use this command for monitoring purposes.

    module.exports.push name: 'Hadoop HDFS NN # Check HA Health', label_true: 'CHECKED', callback: (ctx, next) ->
      return next() unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      ctx.execute
        cmd: mkcmd.hdfs ctx, "hdfs haadmin -checkHealth #{ctx.config.shortname}"
      , next

## Test SSH Fencing

The sshfence option SSHes to the target node and uses fuser to kill the process
listening on the service's TCP port. In order for this fencing option to work,
it must be able to SSH to the target node without providing a passphrase. Thus,
one must also configure the dfs.ha.fencing.ssh.private-key-files option, which
is a comma-separated list of SSH private key files.

    module.exports.push name: 'Hadoop HDFS NN # Check SSH Fencing', label_true: 'CHECKED', callback: (ctx, next) ->
      return next() unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      {hdfs_user} = ctx.config.ryba
      nn_hosts = ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
      for host in nn_hosts
        source = host if host is ctx.config.host
        target = host if host isnt ctx.config.host
      # Disabling key checking shall be considered acceptable between 2 NNs
      ctx.execute
        cmd: "su -l #{hdfs_user.name} -c \"ssh -q -o StrictHostKeyChecking=no #{hdfs_user.name}@#{target} hostname\""
      , (err) ->
        next err, true

## Test FSCK

Check for various inconsistencies on the overall filesystem. Use the command
`hdfs fsck -list-corruptfileblocks` to list the corrupted blocks.

    module.exports.push name: 'Hadoop HDFS NN # Check FSCK', label_true: 'CHECKED', timeout: -1, callback: (ctx, next) ->
      ctx.execute
        cmd: mkcmd.hdfs ctx, "hdfs fsck / | tail -1 | grep HEALTHY"
      , next

## Test User

Create a Unix and Kerberos test user, by default "test" and execute simple HDFS commands to ensure
the NameNode is properly working. Note, those commands are NameNode specific, meaning they only
afect HDFS metadata.

    # module.exports.push name: 'Hadoop HDFS NN # Test User', timeout: -1, label_true: 'CHECKED', callback: (ctx, next) ->
    #   {test_user, test_password, hadoop_group, security} = ctx.config.ryba
    #   {realm, kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5_client
    #   modified = false
    #   do_user = ->
    #     if security is 'kerberos'
    #     then do_user_krb5()
    #     else do_user_unix()
    #   do_user_unix = ->
    #     ctx.execute
    #       cmd: "useradd #{test_user.name} -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Hadoop to test\""
    #       code: 0
    #       code_skipped: 9
    #     , (err, created) ->
    #       return next err if err
    #       modified = true if created
    #       do_run()
    #   do_user_krb5 = ->
    #     ctx.krb5_addprinc
    #       principal: "#{test_user.name}@#{realm}"
    #       password: "#{test_password}"
    #       kadmin_principal: kadmin_principal
    #       kadmin_password: kadmin_password
    #       kadmin_server: admin_server
    #     , (err, created) ->
    #       return next err if err
    #       modified = true if created
    #       do_run()
    #   do_run = ->
    #     # Carefull, this is a dupplicate of
    #     # "HDP HDFS DN # HDFS layout"
    #     ctx.execute
    #       cmd: mkcmd.hdfs ctx, """
    #       if hdfs dfs -ls /user/test 2>/dev/null; then exit 2; fi
    #       hdfs dfs -mkdir /user/#{test_user.name}
    #       hdfs dfs -chown #{test_user.name}:#{hadoop_group.name} /user/#{test_user.name}
    #       hdfs dfs -chmod 755 /user/#{test_user.name}
    #       """
    #       code_skipped: 2
    #     , (err, executed, stdout) ->
    #       modified = true if executed
    #       next err, if modified then ctx.OK else ctx.PASS
    #   do_user()

## Module Dependencies

    mkcmd = require '../lib/mkcmd'


