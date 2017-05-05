
# Phoenix QueryServer Install

Please refer to the Apache Phoenix QueryServer [documentation][phoenix-doc].

    module.exports =  header: 'Phoenix QueryServer Install', handler: ->
      {phoenix, realm} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## Identities

      @system.group header: 'Group', phoenix.group
      @system.user header: 'User', phoenix.user

## IPTables

  | Service             | Port  | Proto  | Parameter                     |
  |---------------------|-------|--------|-------------------------------|
  | Phoenix QueryServer | 8765  | HTTP   | phoenix.queryserver.http.port |

      @tools.iptables
        header: 'IPTables'
        if: @config.iptables.action is 'start'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: phoenix.queryserver.site['phoenix.queryserver.http.port'], protocol: 'tcp', state: 'NEW', comment: "Phoenix QueryServer port" }
        ]

## Packages

      @service header: 'Packages', name: 'phoenix'
      @hdp_select name: 'phoenix-server'

## Kerberos

We use the SPNEGO keytab, so we let hadoop/core handle principal & keytab

      # @krb5.addprinc krb5,
      #     header: 'Kerberos'
      #     if: phoenix.queryserver.site['hbase.security.authentication'] is 'kerberos'
      #     principal: phoenix.queryserver.site['phoenix.queryserver.kerberos.principal'].replace '_HOST', @config.host
      #     randkey: true
      #     keytab: phoenix.queryserver.site['phoenix.queryserver.keytab.file']
      #     uid: phoenix.user.name
      #     gid: phoenix.group.name

## Layout

      @call header: 'Layout', ->
        @system.mkdir
          target: phoenix.pid_dir
          uid: phoenix.user.name
          gid: phoenix.user.name
        @system.mkdir
          target: phoenix.conf_dir
          uid: phoenix.user.name
          gid: phoenix.group.name
        @system.mkdir
          target: phoenix.log_dir
          uid: phoenix.user.name
          gid: phoenix.group.name

## Service

      @call header: 'Service', (options) ->
        @service.init
          header: 'Init Script'
          target: '/etc/init.d/phoenix-queryserver'
          source: "#{__dirname}/../resources/phoenix-queryserver.j2"
          local: true
          context: @config
          mode: 0o0755
        @system.tmpfs
          if_os: name: ['redhat','centos'], version: '7'
          mount: phoenix.pid_dir
          uid: phoenix.user.name
          gid: phoenix.group.name
          perm: '0750'

## HBase Site

      @hconfigure
        header: 'HBase Site'
        target: "#{phoenix.conf_dir}/hbase-site.xml"
        source: "#{__dirname}/../../hbase/resources/hbase-site.xml"
        local: true
        properties: phoenix.queryserver.site
        backup: true
        oef: true

## Env

      @file.render
        header: 'Env'
        target: "#{phoenix.conf_dir}/hbase-env.sh"
        source: "#{__dirname}/../resources/hbase-env.sh.j2"
        local: true
        context: @config
        eof: true

[phoenix-doc]: https://phoenix.apache.org/server
