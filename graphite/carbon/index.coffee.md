
# Graphite Carbon

Graphite Carbon daemons make up the storage backend of a Graphite installation
All of the carbon daemons listen for time-series data and can accept it over a common set of protocols.
However, they differ in what they do with the data once they receive it.

    module.exports = ->
      # 'backup':
      #   'ryba/graphite/carbon/backup'
      # 'check':
      #   'ryba/graphite/carbon/check'
      'configure':
        'ryba/graphite/carbon/configure'
      # 'install':
      #   'ryba/graphite/carbon/install'
      # 'start':
      #   'ryba/graphite/carbon/start'
      # 'status':
      #   'ryba/graphite/carbon/status'
      # 'stop':
      #   'ryba/graphite/carbon/stop'
