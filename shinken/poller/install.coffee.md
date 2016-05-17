
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
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: poller.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Poller" }
        ]
        if: @config.iptables.action is 'start'

## Package

      @call header: 'Packages', timeout: -1, handler: ->
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

      @call header: 'Modules', handler: ->
        installmod = (name, mod) =>
          @call unless_exec: "shinken inventory | grep #{name}", handler: ->
            @download
              destination: "/var/tmp/shinken/#{mod.archive}.zip"
              source: mod.source
              cache_file: "#{mod.archive}.zip"
              unless_exec: "shinken inventory | grep #{name}"
              shy: true
            @extract
              source: "/var/tmp/shinken/#{mod.archive}.zip"
              shy: true
            @execute
              cmd: "shinken install --local /var/tmp/shinken/#{mod.archive}"
            @execute
              cmd: "rm -rf /var/tmp/shinken"
              shy: true
          for subname, submod of mod.modules then installmod subname, submod
        for name, mod of poller.modules then installmod name, mod

## Plugins

      @call header: 'Plugins', timeout: -1, handler: ->
      for plugin in glob.sync "#{__dirname}/resources/plugins/*"
        @download
          destination: "#{shinken.plugin_dir}/#{path.basename plugin}"
          source: plugin
          uid: shinken.user.name
          gid: shinken.group.name
          mode: 0o0755

## Executor

      @call header: 'Executor', handler: ->
        @krb5_addprinc krb5,
          header: 'Kerberos'
          principal: shinken.poller.executor.krb5.unprivileged.principal
          randkey: true
          keytab: shinken.poller.executor.krb5.unprivileged.keytab
          mode: 0o644
        # @krb5_addprinc krb5,
        #   principal: shinken.poller.executor.krb5.privileged.principal
        #   randkey: true
        #   keytab: shinken.poller.executor.krb5.privileged.keytab
        #   mode: 0o644

        @call header: 'Docker', timeout: -1, handler: ->
          @download
            source: "#{@config.mecano.cache_dir or '.'}/shinken-poller-executor.tar"
            destination: '/var/lib/docker_images/shinken-poller-executor.tar'
            md5: true
          @docker_load
            source: '/var/lib/docker_images/shinken-poller-executor.tar'
            if: -> @status -1
          @docker_service
            name: 'poller-executor'
            image: 'ryba/shinken-poller-executor'
            net: 'host'
            volume: [
              "/etc/krb5.conf:/etc/krb5.conf"
              #"/usr/lib64/nagios/plugins:/usr/lib64/nagios/plugins"
              #"#{shinken.poller.executor.krb5.privileged.keytab}:/etc/security/keytabs/crond.privileged.keytab"
              "#{shinken.poller.executor.krb5.unprivileged.keytab}:/etc/security/keytabs/crond.unprivileged.keytab"
            ]

## Dependencies

    path = require 'path'
    glob = require 'glob'
