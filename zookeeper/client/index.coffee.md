
# Zookeeper Client

    module.exports = ->
      'check': [
        'ryba/commons/krb5_user'
        'ryba/zookeeper/server/wait'
        'ryba/zookeeper/client/check'
      ]
      'configure': [
        'masson/commons/java'
        'masson/core/krb5_client'
        'ryba/lib/hdp_select'
        'ryba/lib/write_jaas'
        'ryba/zookeeper/client/configure'
      ]
      'install': [
        'masson/core/iptables'
        'masson/commons/java'
        'ryba/commons/repos'
        'ryba/commons/krb5_user'
        'ryba/zookeeper/server/wait'
        'ryba/zookeeper/client/install'
        'ryba/zookeeper/client/check'
      ]
