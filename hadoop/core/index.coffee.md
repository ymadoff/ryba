
    module.exports =
      use:
        java: implicit: true, module: 'masson/commons/java'
        krb5_client: implicit: true, module: 'masson/core/krb5_client'
        krb5_user: implicit: true, module: 'ryba/commons/krb5_user'
        # hdp_repo: 'ryba/commons/repos'
        hdp: 'ryba/hdp'
        ganglia: 'ryba/ganglia'
        graphite: 'ryba/graphite'
      configure:
        'ryba/hadoop/core/configure'
      commands:
        'install': [
          'ryba/hadoop/core/install'
        ]
