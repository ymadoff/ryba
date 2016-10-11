
# Zookeeper Client

    module.exports =
      use:
        java: implicit: true, module: 'masson/commons/java'
        krb5_client: implicit: true, module: 'masson/core/krb5_client'
        krb5_user: implicit: true, module: 'ryba/commons/krb5_user'
        iptables: implicit: true, module: 'masson/core/iptables'
        zoo_server: 'ryba/zookeeper/server'
        hdp: 'ryba/hdp'
      configure:
        'ryba/zookeeper/client/configure'
      commands:
        'check':
          'ryba/zookeeper/client/check'
        'install': [
          'ryba/zookeeper/client/install'
          'ryba/zookeeper/client/check'
        ]
