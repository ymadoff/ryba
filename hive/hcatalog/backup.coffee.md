
# Hive HCatalog Backup

The backup script dump the content of the hive database as well as the
configuration.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Backup Database

    module.exports.push name: "Hive HCatalog # Backup Database", label_true: 'BACKUPED', handler: ->
      {hive} = @config.ryba
      user = hive.site['javax.jdo.option.ConnectionUserName']
      password = hive.site['javax.jdo.option.ConnectionPassword']
      {engine, db, hostname, port} = parse_jdbc hive.site['javax.jdo.option.ConnectionURL']
      engines_cmd =
        mysql: "mysqldump -u#{user} -p#{password} -h#{hostname} -P#{port} #{db}"
      throw Error 'Database engine not supported' unless engines_cmd[engine]
      @backup
        name: 'db'
        cmd: engines_cmd[engine]
        destination: "/var/backups/hive/"
        interval: month: 1
        retention: count: 2

## Backup Configuration

Backup the active Hive configuration.

    module.exports.push name: "Hive HCatalog # Backup Configuration", label_true: 'BACKUPED', handler: ->
      {hive} = @config.ryba
      @backup
        name: 'conf'
        source: hive.conf_dir
        destination: "/var/backups/hive/"
        interval: month: 1
        retention: count: 2

## Dependencies

    parse_jdbc = require '../../lib/parse_jdbc'
