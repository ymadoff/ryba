
# Hortonworks Smartsense Server Install

    module.exports = header:'HST Server Install', handler: (options) ->
      {smartsense, ssl} = @config.ryba
      {server} = smartsense

## User & Group

      @system.group smartsense.group
      @system.user smartsense.user

## Packages
Note rmp can only be download from the Hortonworks Support Web UI.

      @download
        header: 'Download HST Package'
        source: smartsense.source
        target: "#{smartsense.server.tmp_dir}/smartsense.rpm"
        binary: true
      @system.execute
        header: 'Install HST Package'
        cmd: "rpm -Uvh #{smartsense.server.tmp_dir}/smartsense.rpm"
        if: -> @status -1
      @service.init
        header: 'Init Script'
        target: '/etc/init.d/hst-server'
        source: "#{__dirname}/../resources/hst-server.j2"
        local: true
        mode: 0o0755
        context:
          'pid_dir': smartsense.server.pid_dir
          'user': smartsense.user.name
      @system.tmpfs
        if: -> (options.store['nikita:system:type'] in ['redhat','centos']) and (options.store['nikita:system:release'][0] is '7')
        mount: smartsense.server.pid_dir
        perm: '0750'
        uid: smartsense.user.name
        gid: smartsense.group.name

## Layout

      @call header: 'Layout Directories', ->
        @system.mkdir
          target: smartsense.server.log_dir
          uid: smartsense.user.name
          gid: smartsense.group.name
          mode: 0o0755
        @system.mkdir
          target: smartsense.server.pid_dir
          uid: smartsense.user.name
          gid: smartsense.group.name
          mode: 0o0755
        @system.mkdir
          target: smartsense.server.conf_dir
          uid: smartsense.user.name
          gid: smartsense.group.name
          mode: 0o0755

## SSL Download

      @call
        header: 'SSL Server'
        if: server.ini['server']['ssl_enabled']
      , ->
        @download
          source: ssl.cert
          target: "#{server.conf_dir}/cert.pem"
          uid: smartsense.user.name
          gid: smartsense.group.name
        @download
          source: ssl.key
          target: "#{server.conf_dir}/key.pem"
          uid: smartsense.user.name
          gid: smartsense.group.name

## Setup

      @call header: 'Setup Execution', timeout: -1, ->
        cmd = """
        hst setup -q \
          --accountname=#{server.ini['customer']['account.name']} \
          --smartsenseid=#{server.ini['customer']['smartsense.id']} \
          --email=#{server.ini['customer']['notification.email']} \
          --storage=#{server.ini['server']['storage.dir']} \
          --port=#{server.ini['server']['port']} \
        """
        cmd += """
          --sslCert=#{server.conf_dir}/cert.pem \
          --sslKey=#{server.conf_dir}/key.pem \
          --sslPass=#{server.ssl_pass} \
        """ if server.ini['server']['ssl_enabled']
        cmd += """
          --cluster=#{server.ini['cluster']['name']} \
          #{if server.ini['cluster']['secured'] then '--secured --nostart' else '--nostart'}
        """
        @system.execute
          cmd: cmd
        @file.ini
          header: 'HST Server ini file'
          target: "#{smartsense.server.conf_dir}/hst-server.ini"
          content: smartsense.server.ini
          parse: misc.ini.parse_multi_brackets
          stringify: misc.ini.stringify_multi_brackets
          indent: ''
          separator: '='
          comment: ';'
          uid: smartsense.user.name
          gid: smartsense.group.name
          mode: 0o0750
          merge: true
          backup: true
        @system.execute
          cmd: """
          if [ $(stat -c "%U" #{smartsense.server.conf_dir}/hst-server.ini.bak) == '#{smartsense.user.name}' ]; then exit 3; fi
          chown -R #{smartsense.user.name}:#{smartsense.group.name} #{smartsense.server.conf_dir}/hst-server.ini.bak
          """
          code_skipped: [3,1]
        @system.execute
          cmd: """
          if [ $(stat -c "%U" #{smartsense.user.home}) == '#{smartsense.user.name}' ]; then exit 3; fi
          chown -R #{smartsense.user.name}:#{smartsense.group.name} #{smartsense.user.home}
          """
          code_skipped: [3,1]
        @call
          if: -> @status -3
        , ->
          @service.stop
            name: 'hst-server'
          @system.execute
            shy: true
            cmd: "rm -f #{smartsense.server.log_dir}/hst-server.log"
          @service.start
            name: 'hst-server'


## Dependencies

    misc = require 'nikita/lib/misc'
