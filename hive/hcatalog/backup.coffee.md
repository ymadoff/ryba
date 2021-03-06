
# Hive HCatalog Backup

The backup script dump the content of the hive database as well as the
configuration.

    module.exports =  header: 'Hive HCatalog Backup', label_true: 'BACKUPED', timeout: -1, handler: ->
      {hive} = @config.ryba
      user = hive.hcatalog.site['javax.jdo.option.ConnectionUserName']
      password = hive.hcatalog.site['javax.jdo.option.ConnectionPassword']
      jdbc = db.jdbc hive.hcatalog.site['javax.jdo.option.ConnectionURL']

## Backup Database

      engines_cmd =
        mysql: "mysqldump -u#{user} -p#{password} -h#{jdbc.hostname} -P#{jdbc.port} #{jdbc.database}"
      throw Error 'Database engine not supported' unless engines_cmd[jdbc.engine]
      @tools.backup
        timeout: -1
        label_true: 'BACKUPED'
        header: 'Backup Database'
        name: 'db'
        cmd: engines_cmd[jdbc.engine]
        target: "/var/backups/hive/"
        interval: month: 1
        retention: count: 2

## Backup Configuration

Backup the active Hive configuration.

      @tools.backup
        header: 'Configuration'
        label_true: 'BACKUPED'
        name: 'conf'
        source: hive.hcatalog.conf_dir
        target: "/var/backups/hive/"
        interval: month: 1
        retention: count: 2

## Dependencies

    db = require 'nikita/lib/misc/db'
