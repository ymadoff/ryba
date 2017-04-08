
# Cloudera Manager Server install

    module.exports = header: 'Cloudera Manager Server Install', timeout: -1, handler: ->
      {db} = @config.ryba.cloudera_manager.server
      {java} = @config

## Packages

Install the packages cloudera-scm-agent and cloudera-scm-daemons

      @service
        name: 'mysql'
        if: db.type is 'mysql'
      @service
        name: 'cloudera-manager-daemons'
      @service
        name: 'cloudera-manager-server'

## Env

      @file
        header: 'Environment'
        target: '/etc/default/cloudera-scm-server'
        write: [
          match: RegExp '^export JAVA_HOME=*'
          replace: "export JAVA_HOME=#{java.java_home} # Ryba, don't OVERWRITE"
          append: true
        ]
        backup:true

## Configure

Set the server's hostname in the agent's configuration

      @call header: 'Cloudera Manager Server Configuration', timeout: -1, ->
        mysql_pwd = @config.mysql.server.password
        mysql_exec = "mysql -uroot -p#{mysql_pwd} -h#{db.host} -P#{db.port}"
        @system.execute (
          cmd: """
            #{mysql_exec} -e \"
            create database IF NOT EXISTS #{params.db_name} DEFAULT CHARACTER SET utf8;
            grant all on #{params.db_name}.* TO '#{params.user}'@'localhost' IDENTIFIED BY '#{params.password}';
            grant all on #{params.db_name}.* TO '#{params.user}'@'%' IDENTIFIED BY '#{params.password}';
            flush privileges;
            \"
          """
          unless_exec: "#{mysql_exec} -e 'use #{params.user}'"
        ) for account, params of db.accounts
        @system.execute
          cmd: """
          /usr/share/cmf/schema/scm_prepare_database.sh \
            -h #{db.host} \
            -P #{db.port} \
            --scm-host #{@config.hostname} \
            -u root \
            -p#{mysql_pwd} \
            #{db.type} \
            #{db.main_account.db_name} \
            #{db.main_account.user} \
            #{db.main_account.password}
          """
          unless_exec: "#{mysql_exec} -e 'use #{db.main_account.db_name}'"
