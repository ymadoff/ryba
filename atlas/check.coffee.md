
# Altas Metadata Server Check

Apache Atlas Needs the following components to be started.

    module.exports = header: 'Atlas Check', timeout: -1, label_true: 'STARTED', handler: ->

      @call 'ryba/atlas/wait'
      
      #TODO: Write Atlas Rest Api Check
