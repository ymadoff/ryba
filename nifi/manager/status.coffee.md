# NiFi Manager Status

    module.exports = header: 'NiFi Manager Status', label_true: 'STARTED',label_true: 'STOPPED', handler: ->
      @execute
        cmd: 'service nifi-manager status | grep \'Apache NiFi is running\''
        code_skipped: 1
