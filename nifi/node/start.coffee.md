
# NiFi Node Agent Start

    module.exports = header: 'NiFi Node Start', label_true: 'STARTED', handler: ->

#Wait

Wait for the NiFi Manager to be started.
      
      @wait once: true, 'ryba/nifi/manager/wait'

## Start

      @execute
        cmd: 'service nifi-node start'
        if_exists: '/etc/init.d/nifi-node'
        if_exec: 'service nifi-node status| grep \'Apache NiFi is not running\''
