
# Ganglia Collector

Ganglia Collector is the server which recieves data collected on each
host by the Ganglia Monitor agents.

    module.exports = ->
      # 'backup':
      #   'ryba/ganglia/collector/backup'
      'configure':
        'ryba/ganglia/collector/configure'
      'check':
        'ryba/ganglia/collector/check'
      'install':[
        'masson/core/iptables'
        'masson/commons/httpd'
        'ryba/commons/repos'
        'ryba/ganglia/collector/install'
        'ryba/ganglia/collector/start'
        'ryba/ganglia/collector/check'
      ]
      'start':
        'ryba/ganglia/collector/start'
      # 'status':
      #   'ryba/ganglia/collector/status'
      'stop':
        'ryba/ganglia/collector/stop'
