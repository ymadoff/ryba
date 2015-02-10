
# Ganglia Monitor Stop

Execute these commands on the Ganglia server host machine.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/mecano'

    module.exports.push name: 'Ganglia Collector # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service [
      #   name: 'httpd'
      #   action: 'stop'
      # ,
        # name: 'ganglia-gmetad-3.5.0-99'
        srv_name: 'hdp-gmetad'
        action: 'stop'
      ], next
