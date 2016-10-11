
# Zookeeper Server

Setting up a ZooKeeper server in standalone mode or in replicated mode.

A replicated group of servers in the same application is called a quorum, and in
replicated mode, all servers in the quorum have copies of the same configuration
file. The file is similar to the one used in standalone mode, but with a few
differences.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        krb5_client: implicit: true, module: 'masson/core/krb5_client'
        java: implicit: true, module: 'masson/commons/java'
        hdp: 'ryba/hdp'
        # zoo_client: implicit: true, module: 'ryba/zookeeper/client'
      configure: 
        'ryba/zookeeper/server/configure'
      commands:
        # 'backup':
        #   'ryba/zookeeper/server/backup'
        'check': [
          'ryba/commons/krb5_user'
          'ryba/zookeeper/server/check'
        ]
        'install': [
          'ryba/zookeeper/server/install'
          'ryba/zookeeper/server/start'
          'ryba/zookeeper/server/check'
        ]
        'start':
          'ryba/zookeeper/server/start'
        'status':
          'ryba/zookeeper/server/status'
        'stop':
          'ryba/zookeeper/server/stop'
