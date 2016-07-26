
# Falcon Server

[Apache Falcon](http://falcon.apache.org) is a data processing and management solution for Hadoop designed
for data motion, coordination of data pipelines, lifecycle management, and data
discovery. Falcon enables end consumers to quickly onboard their data and its
associated processing and management tasks on Hadoop clusters.

    module.exports = -> 
      'configure': [
        'ryba/hadoop/core'
        'ryba/commons/krb5_user'
        'ryba/falcon/server/configure'  
      ]
      'install': [
        'masson/core/iptables'
        'ryba/hadoop/core/configure'
        'ryba/commons/krb5_user'
        'ryba/falcon/server/install'
        'ryba/falcon/server/start'
        'ryba/falcon/server/wait'
        'ryba/falcon/server/check'
      ]
      'check':
        'ryba/falcon/server/check'
      'start':
        'ryba/falcon/server/start'
      'stop':
        'ryba/falcon/server/stop'
      'status':
        'ryba/falcon/server/status'

[falcon]: http://falcon.incubator.apache.org/
