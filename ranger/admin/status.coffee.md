
# Ranger Admin Status

Check if Ranger Admin is started

    module.exports = header: 'Ranger Admin Status', label_true: 'STARTED', handler: ->
      @service.status 'ranger-admin'
