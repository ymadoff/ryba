
    module.exports = ->
      'configure': [
        'masson/commons/java/configure'
        'ryba/hbase/common/configure'
      ]
      'install': [
        'masson/core/krb5_client'
        'masson/commons/java'
        'masson/core/yum'
        'ryba/hbase/common/install'
      ]
