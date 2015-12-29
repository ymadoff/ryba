# Cloudera Manager Server install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/commons/java'

## Packages

Instal the packages cloudera-scm-agent and cloudera-scm-daemons

    module.exports.push name: 'Cloudera Manager Server # Packages', timeout: -1, handler: ->
      @service
        name: 'cloudera-manager-daemons'
        # startup: true
      @service
        name: 'cloudera-manager-server'
        # startup: true

## Configure

Set the server's hostname in the agent's configuration

    module.exports.push name: 'Cloudera Manager Server # Configuration', timeout: -1, handler: ->
      {cloudera_manager, db_amin} = @config.ryba
      {server} = cloudera_manager
      {accounts, main_account} = server.db
      mysql_exec = "#{server.db.type} -uroot -p#{server.db.root_password} -h#{server.db.host} -P#{server.db.port} "

      @execute (for account, params of accounts
        cmd: """
        #{mysql_exec} -e "
        create database IF NOT EXISTS #{params.db_name} DEFAULT CHARACTER SET utf8;
        grant all on #{params.db_name}.* TO '#{params.user}'@'localhost' IDENTIFIED BY '#{params.password}';
        grant all on #{params.db_name}.* TO '#{params.user}'@'%' IDENTIFIED BY '#{params.password}';
        flush privileges;
        "
        """
        unless_exec: "#{mysql_exec} -e 'use #{params.user}'"
      )

      @execute
        cmd: """
        /usr/share/cmf/schema/scm_prepare_database.sh \
          -h #{server.db.host} \
          -P #{server.db.port} \
          --scm-host #{@config.hostname} \
          -u root \
          -p#{server.db.root_password} \
          #{server.db.type} \
          #{main_account.db_name} \
          #{main_account.user} \
          #{main_account.password}
        """
        unless_exec: "echo 'nothing to do'"
