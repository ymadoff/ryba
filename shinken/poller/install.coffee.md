
# Shinken Poller Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/shinken'

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
|  shinken-poller   | 7771  |  tcp  |   poller.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'Shinken Poller # IPTables', handler: ->
      {poller} = @config.ryba.shinken
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: poller.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Poller" }
        ]
        if: @config.iptables.action is 'start'

## Package

    module.exports.push name: 'Shinken Poller # Packages', handler: ->
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

    module.exports.push name: 'Shinken Poller # Layout', handler: ->
      {shinken} = @config.ryba
      @chown
        destination: shinken.log_dir
        uid: shinken.user.name
        gid: shinken.group.name
      @execute
        cmd: "su -l #{shinken.user.name} -c 'shinken --init'"
        not_if_exists: "#{shinken.home}/.shinken.ini"

## Additional Modules

    module.exports.push name: 'Shinken Poller # Modules', handler: ->
      {poller} = @config.ryba.shinken
      return unless Object.getOwnPropertyNames(poller.modules).length > 0
      for name, mod of poller.modules
        if mod.archive?
          @download
            destination: "#{mod.archive}.zip"
            source: mod.source
            cache_file: "#{mod.archive}.zip"
            not_if_exec: "shinken inventory | grep #{name}"
          @extract
            source: "#{mod.archive}.zip"
            not_if_exec: "shinken inventory | grep #{name}"
          @install
            cmd: "su -l #{@config.ryba.shinken.user.name} -c 'shinken install --local #{mod.archive}'"
            not_if_exec: "shinken inventory | grep #{name}"
        else throw Error "Missing parameter: archive for poller.modules.#{name}"

## Python Modules

      module.exports.push name: 'Shinken Poller # Python Modules', skip: true, handler: ->
      {poller} = @config.ryba.shinken
      return unless Object.getOwnPropertyNames(poller.python_modules).length > 0
      for name, mod of poller.python_modules
        if mod.archive?
          archive_name = "#{mod.archive}.tar.gz"
          @download
            destination: archive_name
            source: mod.source
            cache_file: archive_name
            not_if_exec: "pip list | grep #{name}"
          @exec
            cmd: "pip install #{mod.archive}.tar.gz"
            not_if_exec: "pip list | grep #{name}"
        else throw Error "Missing parameter: archive for poller.python_modules.#{name}"

## Plugins

    module.exports.push name: 'Shinken Poller # Plugins', timeout: -1, handler: ->
      {shinken} = @config.ryba
      glob "#{__dirname}/resources/plugins/*", (err, plugins) =>
        throw err if err
        for plugin in plugins
          @download
            source: plugin
            destination: "#{shinken.plugin_dir}/#{path.basename plugin}"
            uid: shinken.user.name
            gid: shinken.group.name
            mode: 0o0755

## Kerberos

    module.exports.push name: 'Shinken Poller # Kerberos', skip: true, handler: ->
      {shinken, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: shinken.poller.krb5_user.principal
        randkey: true
        keytab: shinken.poller.krb5_user.keytab
        uid: shinken.user.name
        gid: shinken.group.name
        mode: 0o600
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

## Dependencies

    path = require 'path'
    glob = require 'glob'
