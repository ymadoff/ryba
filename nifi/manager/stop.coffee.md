# NiFi Master Manager Stop

    module.exports = header: 'NiFi Manager Stop', label_true: 'STOPPED', handler: ->
      @execute
        cmd: 'service nifi-manager stop'
        unless_exec: 'service nifi-manager status| grep \'Apache NiFi is not running\''
