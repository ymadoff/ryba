
# MongoDB Server check

## Check

  TODO: Functionnal test

    module.exports =  header: 'MongoDB Client # Check Database', label_true: 'CHECKED', handler: ->
      {mongodb, user} = @config.ryba
      @call once: true, 'ryba/mongodb/router/wait'

      # @call header: 'MongoDB Client # Database Creation', handler: ->
