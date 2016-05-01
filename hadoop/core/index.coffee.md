
    module.exports = ->
      'configure': [
        'masson/commons/java'
        'masson/core/krb5_client'
        'ryba/commons/krb5_user'
        # 'ryba/ganglia/collector'
        # 'ryba/graphite/carbon'
        'ryba/hadoop/core/configure'
      ]
      'install': [
        'masson/core/krb5_client'
        'masson/commons/java'
        'ryba/commons/repos'
        'ryba/hadoop/core/install'
      ]
