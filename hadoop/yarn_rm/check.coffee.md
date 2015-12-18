
# Hadoop Yarn ResourceManager Check

Check the health of the ResourceManager(s).

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/yarn_rm/wait'

## Check Health

Connect to the provided ResourceManager to check its health. This command
`yarn rmadmin -checkHealth {serviceId}` return 0 if the ResourceManager is
healthy, non-zero otherwise. This check is only executed in High Availability
mode.

    module.exports.push header: 'YARN RM # Check HA Health', label_true: 'CHECKED', handler: ->
      return unless @hosts_with_module('ryba/hadoop/yarn_rm').length > 1
      @execute
        cmd: mkcmd.hdfs @, "yarn --config #{@config.ryba.yarn.rm.conf_dir} rmadmin -checkHealth #{@config.shortname}"

# Dependencies

    mkcmd = require '../../lib/mkcmd'

    
