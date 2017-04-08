# Ambari Client

[Ambari-agent][Ambari-agent-install] on hosts enables the ambari server to be
aware of the  hosts where Hadoop will be deployed. The Ambari Server must be 
installed before the agent registration.


    module.exports =
      use:
        java: module: 'masson/commons/java', recommanded: true
        ambari_server: 'ryba/ambari/server', required: true
      configure:
        'ryba/ambari/agent/configure'
      commands:
        'install': [
          'ryba/ambari/agent/install'
          'ryba/ambari/agent/start'
          ]
        'start': 'ryba/ambari/agent/start'
        'stop': 'ryba/ambari/agent/stop'

[Ambari-agent-install]: https://cwiki.apache.org/confluence/display/AMBARI/Installing+ambari-agent+on+target+hosts
