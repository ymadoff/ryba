
# Ganglia Monitor

[Ganglia](http://ganglia.sourceforge.net) is a scalable distributed monitoring
system for high-performance computing systems such as clusters and Grids. It is 
based on a hierarchical design targeted at federations of clusters. Ganglia 
Monitor is the agent to be deployed on each of the hosts.

    module.exports = ->
      # 'backup': 'ryba/ganglia/monitor/backup'
      # 'check': 'ryba/ganglia/monitor/check'
      'install': [
        'ryba/ganglia/monitor/install'
        'ryba/ganglia/monitor/start'
      ]
      'start': 'ryba/ganglia/monitor/start'
      # 'status': 'ryba/ganglia/monitor/status'
      'stop': 'ryba/ganglia/monitor/stop'
