
# Shinken Poller Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/krb5_client'
    module.exports.push 'ryba/shinken'

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
|  shinken-poller   | 7771  |  tcp  |   poller.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push header: 'Shinken Poller # IPTables', handler: ->
      {poller} = @config.ryba.shinken
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

    module.exports.push header: 'Shinken Poller # Packages', timeout: -1, handler: ->
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

## Layout

    module.exports.push header: 'Shinken Poller # Layout', handler: ->
      {shinken} = @config.ryba
      @mkdir
        destination: "#{shinken.user.home}/share"
        uid: shinken.user.name
        gid: shinken.group.name
      @mkdir
        destination: "#{shinken.user.home}/doc"
        uid: shinken.user.name
        gid: shinken.group.name
      @chown
        destination: shinken.log_dir
        uid: shinken.user.name
        gid: shinken.group.name
      @execute
        cmd: 'shinken --init'
        unless_exists: '.shinken.ini'

## Additional Modules

    module.exports.push header: 'Shinken Poller # Modules', handler: ->
      {shinken, shinken:{poller}} = @config.ryba
      return unless Object.keys(poller.modules).length > 0
      for name, mod of poller.modules
        if mod.archive?
          @download
            destination: "#{mod.archive}.zip"
            source: mod.source
            cache_file: "#{mod.archive}.zip"
            unless_exec: "shinken inventory | grep #{name}"
          @extract
            source: "#{mod.archive}.zip"
            unless_exec: "shinken inventory | grep #{name}"
          @execute
            cmd: "shinken install --local #{mod.archive}"
            unless_exec: "shinken inventory | grep #{name}"
        else throw Error "Missing parameter: archive for poller.modules.#{name}"

## Python Modules

      module.exports.push header: 'Shinken Poller # Python Modules', skip: true, handler: ->
      {poller} = @config.ryba.shinken
      return unless Object.keys(poller.python_modules).length > 0
      for name, mod of poller.python_modules
        if mod.archive?
          archive_name = "#{mod.archive}.tar.gz"
          @download
            destination: archive_name
            source: mod.source
            cache_file: archive_name
            unless_exec: "pip list | grep #{name}"
          @exec
            cmd: "pip install #{mod.archive}.tar.gz"
            unless_exec: "pip list | grep #{name}"
        else throw Error "Missing parameter: archive for poller.python_modules.#{name}"

## Plugins

    module.exports.push header: 'Shinken Poller # Plugins', timeout: -1, handler: ->
      {shinken} = @config.ryba
      for plugin in glob.sync "#{__dirname}/resources/plugins/*"
        @download
          destination: "#{shinken.plugin_dir}/#{path.basename plugin}"
          source: plugin
          local_source: true
          uid: shinken.user.name
          gid: shinken.group.name
          mode: 0o0755

## Kerberos

    module.exports.push header: 'Shinken Poller Executor # Kerberos', handler: ->
      {shinken, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: shinken.poller.executor.krb5.unprivileged.principal
        randkey: true
        keytab: shinken.poller.executor.krb5.unprivileged.keytab
        mode: 0o600
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      # @krb5_addprinc
      #   principal: shinken.poller.executor.krb5.privileged.principal
      #   randkey: true
      #   keytab: shinken.poller.executor.krb5.privileged.keytab
      #   mode: 0o600
      #   kadmin_principal: kadmin_principal
      #   kadmin_password: kadmin_password
      #   kadmin_server: admin_server

    module.exports.push header: 'Shinken Poller Executor # Docker', timeout: -1, handler: ->
      {shinken} = @config.ryba
      @upload
        source: "#{@config.mecano.cache_dir or '.'}/shinken-poller-executor.tar"
        destination: '/var/lib/docker_images/shinken-poller-executor.tar'
        binary: true
      @docker_load
        source: '/var/lib/docker_images/shinken-poller-executor.tar'
      @docker_run
        name: 'poller-unprivileged-executor'
        image: 'ryba/shinken-poller-executor'
        env: "KRB5_PRINCIPAL=#{shinken.poller.executor.krb5.unprivileged.principal}"
        volume: [
          "/etc/krb5.conf:/etc/krb5.conf"
          "#{shinken.poller.executor.krb5.unprivileged.keytab}:/etc/security/keytabs/crond.keytab"
        ]
        service: true
      # @docker_run
      #   name: 'poller-privileged-executor'
      #   image: 'ryba/shinken-poller-executor'
      #   env: "KRB5_PRINCIPAL=#{shinken.poller.executor.krb5.privileged.principal}"
      #   volume: "#{shinken.poller.executor.krb5.privileged.keytab}:/etc/security/keytabs/crond.keytab"
      #   service: true

## Dependencies

    path = require 'path'
    glob = require 'glob'
