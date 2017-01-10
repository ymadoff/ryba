
# Phoenix QueryServer Check

    module.exports = header: 'Phoenix QueryServer Check', label_true: 'CHECKED', handler: ->

## Wait

      @call once: true, 'ryba/phoenix/queryserver/wait'
