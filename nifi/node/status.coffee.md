# NiFi Node Status

    module.exports = header: 'NiFi Node Status', label_true: 'STARTED',label_true: 'STOPPED', handler: ->
      @execute
        cmd: 'service nifi-node status | grep \'Apache NiFi is running\''
        code_skipped: 1
