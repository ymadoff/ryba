
# Falcon Client

[Apache Falcon](http://falcon.apache.org) is a data processing and management solution for Hadoop designed
for data motion, coordination of data pipelines, lifecycle management, and data
discovery. Falcon enables end consumers to quickly onboard their data and its
associated processing and management tasks on Hadoop clusters.

    module.exports = -> 
      'configure': [
        'ryba/hadoop/core'
        'ryba/falcon/client/configure'  
      ]
      'install': [
        'ryba/commons/krb5_user'
        'ryba/falcon/client/install'
        'ryba/falcon/client/check'
      ]
      'check': [
        'ryba/falcon/server/wait'
        'ryba/falcon/client/check'
      ]

[falcon]: http://falcon.incubator.apache.org/
