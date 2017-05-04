
# Yarn Client Check

    module.exports = header: 'YARN Client Check', label_true: 'CHECKED', handler: ->

## Wait

Wait for all YARN services to be started.

      @call once: true, 'ryba/hadoop/yarn_ts/wait'
      @call once: true, 'ryba/hadoop/yarn_rm/wait'

## Check CLI

      @system.execute
        header: 'CLI'
        cmd: mkcmd.test @, 'yarn application -list'

## Dependencies

    mkcmd = require '../../lib/mkcmd'
