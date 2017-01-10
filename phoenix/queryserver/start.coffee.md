
# Phoenix QueryServer Start

    module.exports = header: 'Phoenix QueryServer Start', label_true: 'STARTED', handler: ->
      @service.start name: 'phoenix-queryserver'
