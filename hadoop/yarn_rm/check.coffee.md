
# Hadoop Yarn ResourceManager Check

Check the health of the ResourceManager(s).

    module.exports = header: 'YARN RM Check', label_true: 'CHECKED', handler: ->
      {yarn} = @config.ryba

## Wait

Wait for the ResourceManager.

      @call once: true, 'ryba/hadoop/yarn_rm/wait'

## Check Health

Connect to the provided ResourceManager to check its health. This command
`yarn rmadmin -checkHealth {serviceId}` return 0 if the ResourceManager is
healthy, non-zero otherwise. This check only apply to High Availability
mode.

      @system.execute
        header: 'HA Health'
        if: @contexts('ryba/hadoop/yarn_rm').length > 1
        cmd: mkcmd.hdfs @, "yarn --config #{yarn.rm.conf_dir} rmadmin -checkHealth #{@config.shortname}"

# Dependencies

    mkcmd = require '../../lib/mkcmd'


