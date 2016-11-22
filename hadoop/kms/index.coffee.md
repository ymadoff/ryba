
# Hadoop KMS

Hadoop KMS is a cryptographic key management server based on Hadoop’s
KeyProvider API.

It provides a client and a server components which communicate over HTTP using a
REST API.

    module.exports =
      use:
        java: implicit: true, module: 'masson/commons/java'
        hadoop_core: implicit: true, module: 'ryba/hadoop/core'
        zoo_servers: 'ryba/zookeeper/server'
      configure:
        'ryba/hadoop/kms/configure'
      commands:
        'check':
          'ryba/hadoop/kms/check'
        'install': [
          'ryba/hadoop/kms/install'
          'ryba/hadoop/kms/check'
        ]
