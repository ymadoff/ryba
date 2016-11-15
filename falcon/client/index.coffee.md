
# Falcon Client

[Apache Falcon](http://falcon.apache.org) is a data processing and management solution for Hadoop designed
for data motion, coordination of data pipelines, lifecycle management, and data
discovery. Falcon enables end consumers to quickly onboard their data and its
associated processing and management tasks on Hadoop clusters.

    module.exports =
      use:
        hadoop_core: implicit: true, module: 'ryba/hadoop/core'
        krb5_client: implicit: true, module: 'masson/core/krb5_client'
        krb5_user: implicit: true, module: 'ryba/commons/krb5_user'
      configure:
        'ryba/falcon/client/configure'
      commands:
        'install': [
          'ryba/falcon/client/install'
          'ryba/falcon/client/check'
        ]
        'check':
          'ryba/falcon/client/check'

[falcon]: http://falcon.incubator.apache.org/
