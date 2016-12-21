
# WebHCat Status

Check if the RegionServer is running. The process ID is located by default
inside "/var/run/webhcat/webhcat.pid".

    module.exports = header: 'WebHCat Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        name: 'hive-webhcat-server'
