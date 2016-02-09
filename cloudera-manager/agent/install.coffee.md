# Cloudera Manager Agent install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/commons/java'

## Packages

Instal the packages cloudera-scm-agent and cloudera-scm-daemons

    module.exports.push header: 'Cloudera Manager Agent # Packages', timeout: -1, handler: ->
      @service
        name: 'cloudera-manager-daemons'
        # startup: true
      @service
        name: 'cloudera-manager-agent'
        # startup: true

## Configure

Set the server's hostname in the agent's configuration

    module.exports.push header: 'Cloudera Manager Agent # Configuration', timeout: -1, handler: ->
      {agent} = @config.ryba.cloudera_manager
      @write
        destination: "#{agent.conf_dir}config.ini"
        write: [
          match: /^server_host=.*$/m
          replace: "server_host=#{agent.ini.server['hostname']}"
          # append: true
        ],
        backup: true
