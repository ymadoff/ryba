
# Zookeeper Server

Setting up a ZooKeeper server in standalone mode or in replicated mode.

A replicated group of servers in the same application is called a quorum, and in
replicated mode, all servers in the quorum have copies of the same configuration
file. The file is similar to the one used in standalone mode, but with a few
differences.

    module.exports = ->
      'configure': [
        'masson/commons/java'
        'ryba/lib/hdp_select'
        'ryba/lib/write_jaas'
        'ryba/zookeeper/client/configure'
        'ryba/zookeeper/server/configure'
      ]
      # 'backup':
      #   'ryba/zookeeper/server/backup'
      'check': [
        'ryba/commons/krb5_user'
        'ryba/zookeeper/server/wait'
        'ryba/zookeeper/server/check'
      ]
      'install': [
        'masson/core/iptables'
        'masson/commons/java'
        'ryba/commons/repos'
        'masson/core/krb5_client/wait'
        'ryba/zookeeper/server/install'
        'ryba/zookeeper/server/start'
        'ryba/zookeeper/server/check'
      ]
      'start': [
        'masson/core/krb5_client/wait'
        'ryba/zookeeper/server/start'
      ]
      'status':
        'ryba/zookeeper/server/status'
      'stop':
        'ryba/zookeeper/server/stop'
