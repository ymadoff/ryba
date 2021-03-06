
# Shinken Poller Install

    module.exports = header: 'Shinken Poller Install', handler: ->
      {shinken} = @config.ryba
      {poller} = @config.ryba.shinken
      {realm} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
|  shinken-poller   | 7771  |  tcp  |   poller.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      rules = [{ chain: 'INPUT', jump: 'ACCEPT', dport: poller.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Poller" }]
      for name, mod of poller.modules
        if mod.config?.port?
          rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: mod.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Poller #{name}" }
      @tools.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: poller.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Poller" }
        ]
        if: @config.iptables.action is 'start'

## Package

      @call header: 'Packages', timeout: -1, ->
        @service name: 'net-snmp'
        @service name: 'net-snmp-utils'
        @service name: 'httpd'
        # @service name: 'perl-Net-SNMP'
        @service name: 'fping'
        @service name: 'krb5-devel'
        @service name: 'zlib-devel'
        @service name: 'bzip2-devel'
        @service name: 'openssl-devel'
        @service name: 'ncurses-devel'
        @service name: 'shinken-poller'

## Additional Modules

      @call header: 'Modules', ->
        installmod = (name, mod) =>
          @call unless_exec: "shinken inventory | grep #{name}", ->
            @file.download
              target: "#{shinken.build_dir}/#{mod.archive}.zip"
              source: mod.source
              cache_file: "#{mod.archive}.zip"
              unless_exec: "shinken inventory | grep #{name}"
              shy: true
            @tools.extract
              source: "#{shinken.build_dir}/#{mod.archive}.zip"
              shy: true
            @system.execute
              cmd: "shinken install --local #{shinken.build_dir}/#{mod.archive}"
            @system.execute
              cmd: "rm -rf #{shinken.build_dir}"
              shy: true
          for subname, submod of mod.modules then installmod subname, submod
        for name, mod of poller.modules then installmod name, mod

## Plugins

      @call header: 'Plugins', timeout: -1, ->
      for plugin in glob.sync "#{__dirname}/resources/plugins/*"
        @file.download
          target: "#{shinken.plugin_dir}/#{path.basename plugin}"
          source: plugin
          uid: shinken.user.name
          gid: shinken.group.name
          mode: 0o0755

## Executor

      @call header: 'Executor', ->
        @krb5.addprinc krb5,
          header: 'Kerberos'
          principal: shinken.poller.executor.krb5.principal
          randkey: true
          keytab: shinken.poller.executor.krb5.keytab
          mode: 0o644

        @call header: 'Docker', timeout: -1, ->
          @file.download
            source: "#{@config.nikita.cache_dir or '.'}/shinken-poller-executor.tar"
            target: '/var/lib/docker_images/shinken-poller-executor.tar'
            md5: true
          @docker.load
            source: '/var/lib/docker_images/shinken-poller-executor.tar'
            if: -> @status -1
          @file
            target: "#{shinken.poller.executor.resources_dir}/cronfile"
            content: """
            01 */9 * * * #{shinken.user.name} /usr/bin/kinit #{shinken.poller.executor.krb5.principal} -kt #{shinken.poller.executor.krb5.keytab}
            """
            eof: true
          @docker.service
            name: 'poller-executor'
            image: 'ryba/shinken-poller-executor'
            net: 'host'
            volume: [
              "/etc/krb5.conf:/etc/krb5.conf:ro"
              "/etc/localtime:/etc/localtime:ro"
              #"/usr/lib64/nagios/plugins:/usr/lib64/nagios/plugins"
              #"#{shinken.poller.executor.krb5.privileged.keytab}:#{shinken.poller.executor.krb5.privileged.keytab}"
              "#{shinken.poller.executor.resources_dir}:/home/#{shinken.user.name}/plugins/resources"
              "#{shinken.poller.executor.resources_dir}/cronfile:/etc/cron.d/1cron"
              "#{shinken.poller.executor.krb5.keytab}:#{shinken.poller.executor.krb5.keytab}"
            ]

## Dependencies

    path = require 'path'
    glob = require 'glob'
