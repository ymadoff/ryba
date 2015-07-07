
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
      daemon = 'poller'
      ctx
      .service name: 'net-snmp'
      .service name: 'net-snmp-utils'
      .service name: 'php-pecl-json'
      .service name: 'wget'
      .service name: 'httpd'
      .service name: 'php'
      .service name: 'net-snmp-perl'
      .service name: 'perl-Net-SNMP'
      .service name: 'fping'
      #.service name: "shinken-#{daemon}"
      .execute cmd: "yum -y --disablerepo=HDP-UTILS-1.1.0.20 install shinken-#{daemon}"
      .write
        destination: "/etc/init.d/shinken-#{daemon}"
        write: for k, v of {
            'user': shinken.user.name
            'group': shinken.group.name }
          match: ///^#{k}=.*$///mg
          replace: "#{k}=#{v}"
          append: true
      .write
        destination: "/etc/shinken/daemons/#{daemon}d.ini"
        write: for k, v of {
            'user': shinken.user.name
            'group': shinken.group.name }
          match: ///^#{k}=.*$///mg
          replace: "#{k}=#{v}"
          append: true
      .chown
        destination: path.join shinken.log_dir
        uid: shinken.user.name
        gid: shinken.group.name
      .then next

## Kerberos

    # module.exports.push name: 'Shinken # Kerberos', handler: (ctx, next) ->
    #   {shinken, realm} = ctx.config.ryba
    #   {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
    #   ctx.krb5_addprinc
    #     principal: shinken.principal
    #     randkey: true
    #     keytab: shinken.keytab
    #     uid: shinken.user.name
    #     gid: shinken.group.name
    #     mode: 0o600
    #     kadmin_principal: kadmin_principal
    #     kadmin_password: kadmin_password
    #     kadmin_server: admin_server
    #   .then next

## Module dependencies

    path = require 'path'
