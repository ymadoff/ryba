
# Falcon

[Apache Falcon](http://falcon.apache.org) is a data processing and management solution for Hadoop designed
for data motion, coordination of data pipelines, lifecycle management, and data
discovery. Falcon enables end consumers to quickly onboard their data and its
associated processing and management tasks on Hadoop clusters.

    module.exports = -> 
      'configure': [
        'ryba/hadoop/core'
        'ryba/commons/krb5_user'
        'ryba/falcon/configure'  
      ]
      'install': [
        'masson/core/iptables'
        'ryba/lib/hdp_select'
        'ryba/hadoop/core/configure'
        'ryba/commons/krb5_user'
        'ryba/falcon/install'
        'masson/core/krb5_client/wait'
        'ryba/falcon/start' 
        # 'ryba/falcon/check'
      ]
      'check': [
        'masson/core/krb5_client/wait'
        'ryba/falcon/start' 
        'ryba/falcon/check'
      ]
      'start': [
        'masson/core/krb5_client/wait'
        'ryba/falcon/start' 
      ]
      'stop': [
        'ryba/falcon/stop'
      ]
      'status': [
        'ryba/falcon/status'
      ]

[falcon]: http://falcon.incubator.apache.org/
