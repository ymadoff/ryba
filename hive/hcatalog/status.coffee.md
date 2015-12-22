
# Hive HCatalog Status

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Status

Check if the HCatalog is running. The process ID is located by default
inside "/var/lib/hive-hcatalog/hcat.pid".

    module.exports.push header: 'Hive HCatalog # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'hive-hcatalog-server'
        if_exists: '/etc/init.d/hive-hcatalog-server'
