
# WebHCat Status

Check if the RegionServer is running. The process ID is located by default
inside "/var/run/webhcat/webhcat.pid".

    module.exports = header: 'WebHCat Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'hive-webhcat-server'
        if_exists: '/etc/init.d/hive-webhcat-server'
