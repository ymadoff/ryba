
# NiFi Manager Start

    module.exports = header: 'NiFi Manager Start', label_true: 'STARTED', handler: ->
      @execute
        cmd: 'service nifi-manager start'
        if_exec: 'service nifi-manager status| grep \'Apache NiFi is not running\''
