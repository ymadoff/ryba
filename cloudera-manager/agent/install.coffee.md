
# Cloudera Manager Agent install

    module.exports = header: 'Cloudera Manager Agent Install', timeout: -1, handler: ->
      {agent} = @config.ryba.cloudera_manager
      {java} = @config

## Packages

Instal the packages cloudera-scm-agent and cloudera-scm-daemons

      @service
        name: 'cloudera-manager-daemons'
        # startup: true
      @service
        name: 'cloudera-manager-agent'
        # startup: true

## Configure

Set the server's hostname in the agent's configuration

      @file
        header: 'Configuration'
        target: "#{agent.conf_dir}/config.ini"
        write: [
          match: /^server_host=.*$/m
          replace: "server_host=#{agent.ini.server['hostname']}"
          # append: true
        ],
        backup: true

## Env

      @file
        header: 'Env'
        target: '/etc/default/cloudera-scm-agent'
        write: [
          match: RegExp '^export JAVA_HOME=*'
          replace: "export JAVA_HOME=#{java.java_home} # Ryba, don't OVERWRITE"
          append: true
        ]
        backup:true
