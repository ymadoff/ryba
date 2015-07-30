
# Shinken Poller Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/shinken'
    module.exports.push require('./index').configure

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
|  shinken-poller   | 7771  |  tcp  |   poller.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'Shinken Poller # IPTables', handler: (ctx, next) ->
      {poller} = ctx.config.ryba.shinken
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: poller.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Poller" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

## Install

    module.exports.push name: 'Shinken Poller # Install', handler: (ctx, next) ->
      {shinken} = ctx.config.ryba
      ctx
      .service name: 'net-snmp'
      .service name: 'net-snmp-utils'
      .service name: 'httpd'
      .service name: 'net-snmp-perl'
      .service name: 'perl-Net-SNMP'
      .service name: 'fping'
      .service name: 'krb5-devel'
      .service name: 'zlib-devel'
      .service name: 'bzip2-devel'
      .service name: 'openssl-devel'
      .service name: 'ncurses-devel'
      #.service name: 'python27'
      #.service name: 'python27-python-pip'
      #.service name: 'python27-python-devel'
      #.service name: 'nagios-plugins' # Will be installed automatically by shinken poller
      #.service name: 'shinken-poller'
      .execute cmd: "yum -y --disablerepo=HDP-UTILS-1.1.0.20 install shinken-poller"
      .chown
        destination: path.join shinken.log_dir
        uid: shinken.user.name
        gid: shinken.group.name
      .execute
        cmd: "su -l #{shinken.user.name} -c 'shinken --init'"
        not_if_exists: "#{shinken.home}/.shinken.ini"
      .then next

## Additional Modules

    module.exports.push name: 'Shinken Poller # Modules', handler: (ctx, next) ->
      {poller} = ctx.config.ryba.shinken
      return next() unless Object.getOwnPropertyNames(poller.modules).length > 0
      download = []
      extract = []
      exec = []
      for name, mod of poller.modules
        if mod.archive?
          download.push
            destination: "#{mod.archive}.zip"
            source: mod.source
            cache_file: "#{mod.archive}.zip"
            not_if_exec: "shinken inventory | grep #{name}"
          extract.push
            source: "#{mod.archive}.zip"
            not_if_exec: "shinken inventory | grep #{name}"
          install.push
            cmd: "su -l #{ctx.config.ryba.shinken.user.name} -c 'shinken install --local #{mod.archive}'"
            not_if_exec: "shinken inventory | grep #{name}"
        else return next Error "Missing parameter: archive for poller.modules.#{name}"
      ctx
      .download download
      .extract extract
      .execute exec
      .then next

## Alternative Python

Shinken modules needs python 2.7 but yum needs python 2.6 so we install
an alternative python without replacing python 2.6

    module.exports.push name: 'Shinken Poller # Python 2.7', skip: true, handler: (ctx, next) ->
      {poller} = ctx.config.ryba.shinken
      ctx
        not_if_exec: '/usr/local/bin/python2.7'
      .extract
        source: "#{poller.python.archive}.tgz"
        not_if_exists: '/usr/local/bin/python2.7'
      .execute
        cmd: """
        echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf
        ldconfig
        """
        not_if_exists: '/etc/ld.so.conf.d/local.conf'
      .execute
        cmd: """
        cd #{poller.python.archive}
        ./configure --prefix=/usr/local --enable-shared
        make && make altinstall
        """
        not_if_exists: '/usr/local/bin/python2.7'
      .then next

## Python Modules

      module.exports.push name: 'Shinken Poller # Python Modules', skip: true, handler: (ctx, next) ->
      {poller} = ctx.config.ryba.shinken
      return next() unless Object.getOwnPropertyNames(poller.python_modules).length > 0
      download = []
      extract = []
      exec = []
      for name, mod of poller.python_modules
        if mod.archive?
          archive_name = "#{mod.archive}.tar.gz"
          download.push
            destination: archive_name
            source: mod.source
            cache_file: archive_name
            not_if_exec: "pip list | grep #{name}"
          exec.push
            cmd: "pip install #{mod.archive}.tar.gz"
            not_if_exec: "pip list | grep #{name}"
        else return next Error "Missing parameter: archive for poller.python_modules.#{name}"
      ctx
      .download download
      .execute exec
      .then next

## Plugins

    module.exports.push name: 'Shinken Poller # Plugins', timeout: -1, handler: (ctx, next) ->
      {shinken} = ctx.config.ryba
      glob "#{__dirname}/../../resources/shinken/plugins/*", (err, plugins) ->
        return next err if err
        plugins = for plugin in plugins
          source: plugin
          destination: "#{shinken.plugin_dir}/#{path.basename plugin}"
          uid: shinken.user.name
          gid: shinken.group.name
          mode: 0o0755
        ctx
        .download plugins
        .then next

## Kerberos

    module.exports.push name: 'Shinken Poller # Kerberos', handler: (ctx, next) ->
      {shinken, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: shinken.poller.krb5_user.principal
        randkey: true
        keytab: shinken.poller.krb5_user.keytab
        uid: shinken.user.name
        gid: shinken.group.name
        mode: 0o600
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      .then next

## Dependencies

    path = require 'path'
    glob = require 'glob'
