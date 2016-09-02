
# Shinken Arbiter Status

    module.exports = header: 'Shinken Arbiter # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status name: 'shinken-arbiter'
