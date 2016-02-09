# Cloudera Manager Server install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/commons/java'

## Packages

Instal the packages cloudera-scm-agent and cloudera-scm-daemons

    module.exports.push header: 'Cloudera Manager Server # Packages', timeout: -1, handler: ->
      @service
        name: 'cloudera-manager-daemons'
      @service
        name: 'cloudera-manager-server'

## Configure

Set the server's hostname in the agent's configuration

    module.exports.push header: 'Cloudera Manager Server # Configuration', timeout: -1, handler: ->
      {cloudera_manager, db_admin} = @config.ryba
      {server} = cloudera_manager
      mysql_exec = "#{db_admin.path} -u#{db_admin.username} -p#{db_admin.password} -h#{db_admin.host} -P#{db_admin.port}"
      @call ->
        for account, params of server.db.accounts
          @execute
            cmd: """
              #{mysql_exec} -e \"
              create database IF NOT EXISTS #{params.db_name} DEFAULT CHARACTER SET utf8;
              grant all on #{params.db_name}.* TO '#{params.user}'@'localhost' IDENTIFIED BY '#{params.password}';
              grant all on #{params.db_name}.* TO '#{params.user}'@'%' IDENTIFIED BY '#{params.password}';
              flush privileges;
              \"
            """
            unless_exec: "#{mysql_exec} -e 'use #{params.user}'"
      @execute
        cmd: """
        /usr/share/cmf/schema/scm_prepare_database.sh \
          -h #{db_admin.host} \
          -P #{db_admin.port} \
          --scm-host #{@config.hostname} \
          -u root \
          -p#{db_admin.password} \
          #{server.db.type} \
          #{server.db.main_account.db_name} \
          #{server.db.main_account.user} \
          #{server.db.main_account.password}
        """
        unless_exec: "#{mysql_exec} -e 'use #{server.db.main_account.db_name}'"
