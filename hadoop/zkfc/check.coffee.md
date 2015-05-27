
# Hadoop ZKFC Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Test SSH Fencing

The sshfence option SSHes to the target node and uses fuser to kill the process
listening on the service's TCP port. In order for this fencing option to work,
it must be able to SSH to the target node without providing a passphrase. Thus,
one must also configure the dfs.ha.fencing.ssh.private-key-files option, which
is a comma-separated list of SSH private key files.

    module.exports.push name: 'HDFS ZKFC # Check SSH Fencing', label_true: 'CHECKED', handler: (ctx, next) ->
      return next() unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      {hdfs} = ctx.config.ryba
      nn_hosts = ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
      for host in nn_hosts
        source = host if host is ctx.config.host
        target = host if host isnt ctx.config.host
      # Disabling key checking shall be considered acceptable between 2 NNs
      ctx.execute
        cmd: "su -l #{hdfs.user.name} -c \"ssh -q -o StrictHostKeyChecking=no #{hdfs.user.name}@#{target} hostname\""
      .then next