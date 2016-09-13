
# Hortonworks Smartsense Install
    
    module.exports = header:'HST Agent Install', handler: ->
      {smartsense, ssl} = @config.ryba
      {agent} = smartsense

## Wait Server
      
      @call once:true, 'ryba/smartsense/server/wait'
    
## User & Group
      
      @group smartsense.group
      @user smartsense.user

## Packages  
Note rmp can only be download from the Hortonworks Support Web UI.
      
      @download
        header: 'Download HST Package'
        source: smartsense.source
        target: "#{smartsense.agent.tmp_dir}/smartsense.rpm"
        binary: true       
      @execute
        header: 'Install HST Package'
        cmd: "rpm -Uvh #{smartsense.agent.tmp_dir}/smartsense.rpm"
        if: -> @status -1

## Layout

      @call header: 'Layout Directories', handler: ->
        @mkdir
          target: smartsense.agent.log_dir
          uid: smartsense.user.name
          gid: smartsense.group.name
          mode: 0o0755
        @mkdir
          target: smartsense.agent.pid_dir
          uid: smartsense.user.name
          gid: smartsense.group.name
          mode: 0o0755
        @mkdir
          target: smartsense.agent.conf_dir
          uid: smartsense.user.name
          gid: smartsense.group.name
          mode: 0o0755

## Setup
        
      @call header: 'Setup Execution', timeout: -1, handler: ->
        @file.ini
          header: 'HST Agent ini file'
          target: "#{smartsense.agent.conf_dir}/hst-server.ini"
          content: smartsense.agent.ini
          parse: misc.ini.parse_multi_brackets_multi_lines
          stringify: misc.ini.stringify_multi_brackets
          indent: ''
          separator: '='
          comment: ';'
          uid: smartsense.user.name
          gid: smartsense.group.name
          mode: 0o0750
          merge: true
          backup: true
        @execute
          cmd: "hst setup-agent  --server=#{agent.server_host}"
        @execute
          header: 'Remove execution log files'
          shy: true
          cmd: "rm -f #{smartsense.agent.log_dir}/hst-agent.log"
        @execute
          cmd: """
          if [ $(stat -c "%U" #{smartsense.user.home}) == '#{smartsense.user.name}' ]; then exit 3; fi
          chown -R #{smartsense.user.name}:#{smartsense.group.name} #{smartsense.user.home}
          """
          code_skipped: [3,1]

## Dependencies

    misc = require 'mecano/lib/misc'
