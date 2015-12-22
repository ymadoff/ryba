
# WebHCat Status

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Status

Check if the RegionServer is running. The process ID is located by default
inside "/var/run/webhcat/webhcat.pid".

    module.exports.push header: 'WebHCat # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'hive-webhcat-server'
        if_exists: '/etc/init.d/hive-webhcat-server'
