# Ambari Agent Install

The ambari server must be set in the configuration file.

    module.exports = header: 'Ambari Agent Install', timeout: -1, handler: ->
      {ambari_agent} = @config.ryba

## Package installation

      @service
        header: 'Ambari Agent Startup'
        name: 'ambari-agent'
        startup: true

## Ambari Agent Configure

      @file.ini
        header: 'Ambari Agent Configure'
        target: "#{ambari_agent.conf_dir}/ambari-agent.ini"
        content: ambari_agent.ini
        parse: misc.ini.parse_multi_brackets_multi_lines
        stringify: misc.ini.stringify_multi_brackets
        indent: ''
        merge: true
        comment: '#'
        backup: true


    misc = require 'mecano/lib/misc'
