
# Phoenix QueryServer Stop

    module.exports = header: 'Phoenix QueryServer Stop', label_true: 'STOPPED', handler: ->
      @service.stop name: 'phoenix-queryserver'
