# Ambari Client

[Ambari-agent][Ambari-agent-install] on hosts enables the ambari server to be
aware of the  hosts where Hadoop will be deployed.
The ambari server must be installed before performing manual registration.


    module.exports = ->
      'configure': 'ryba/ambari/agent/configure'
      'install': [
        'masson/commons/java'
        'ryba/ambari/agent/install'
        'ryba/ambari/agent/start'
        ]
      'start': 'ryba/ambari/agent/start'
      'stop': 'ryba/ambari/agent/stop'

[Ambari-agent-install]: https://cwiki.apache.org/confluence/display/AMBARI/Installing+ambari-agent+on+target+hosts
