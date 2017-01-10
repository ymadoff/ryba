
# Phoenix QueryServer Status

    module.exports = header: 'Phoenix QueryServer Status', label_true: 'STARTED',label_true: 'STOPPED', handler: ->
      @service.status
        name: 'phoenix-queryserver'
