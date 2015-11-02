# HBase Thrift Gateway

Note, Hortonworks recommand to grant administrative access to the _acl_ table
for the service princial define by "hbase.thirft.kerberos.principal". For example,
run the command `grant '$USER', 'RWCA'`. Ryba isnt doing it because we didn't
have usecase for it yet.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/hadoop/core'
    module.exports.push 'ryba/hbase'
    # module.exports.push require('./index').configure
    module.exports.push 'ryba/lib/hconfigure'
    module.exports.push 'ryba/lib/hdp_select'

## IPTables

| Service                    | Port | Proto | Info                   |
|----------------------------|------|-------|------------------------|
| HBase Thrift Server        | 9090 | http  | hbase.thrift.port      |
| HBase Thrift Server Web UI | 9095 | http  | hbase.thrift.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'HBase Thrift # IPTables', handler: ->
      {hbase} = @config.ryba
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.thrift.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Thrift Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.thrift.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Thrift Info Web UI" }
        ]
        if: @config.iptables.action is 'start'

###
DONE: Dependecies for thrift which are Autoconf - Automake - Bison
Wait: checkinf i the version given by the os are the needed one
Currently centos give Autoconf 2.63 - Automake 1.11 - Bison 2.4.1
Needed for thrift     Autoconf 2.69 - Automake 1.14 - Bison 2.5
TODO: Installing Thrift Compiler
## Thrift Autoconf

    module.exports.push name: 'Thrift # Install Autoconf', timeout: -1, handler: (options) ->
      {hbase} = @config.ryba
      @call (_, callback) ->
        @execute
          cmd: "autoconf --version | egrep '.*[0-9]\\.[0-9]{2}' | awk '{ print $4 }'"
        , (err, executed, stdout) ->
          return callback err if err and err.code isnt 2
          stdout = '' if err
          autoconf_version =  stdout.trim()
          if autoconf_version == hbase.thrift.autoconf.version
            options.log "autoconf :already up to date version #{hbase.thrift.autoconf.version}"
            callback null, false
          else
            options.log "autoconf : is not installed "
            callback null, true
      @download
        source: hbase.thrift.autoconf.url
        destination: hbase.thrift.autoconf.destination
        binary: true
        if: -> @status -1
      @execute
        cmd: """
        rm -Rf #{hbase.thrift.autoconf.tmp}
        mkdir #{hbase.thrift.autoconf.tmp}
        tar xzf #{hbase.thrift.autoconf.destination} -C #{hbase.thrift.autoconf.tmp} --strip-components=1
        cd #{hbase.thrift.autoconf.tmp}
        ./configure --prefix=/usr
        make && make install
        cd ..
        rm -Rf #{hbase.thrift.autoconf.destination}
        rm -Rf #{hbase.thrift.autoconf.tmp}
        """
        trap_on_error: true
        if: -> @status -2

## Thrift Automake

    module.exports.push name: 'Thrift # Install Automake', timeout: -1, handler: (options) ->
      {hbase} = @config.ryba
      options.log? "Check if Automake is installed "
      @call (_, callback) ->
        @execute
          cmd: "automake --version | egrep '.*[0-9]\\.[0-9]{2}' | awk '{ print $4 }'"
        , (err, executed, stdout) ->
          return callback err if err and err.code isnt 2
          stdout = '' if err
          automake_version =  stdout.toString('utf-8').trim()
          if automake_version ==  hbase.thrift.automake.version
            options.log "automake :already up to date version #{hbase.thrift.automake.version}"
            callback null, false
          else
            options.log "automake : is not installed"
            callback null, true
      @download
        source: hbase.thrift.automake.url
        destination: hbase.thrift.automake.destination
        binary: true
        if: -> @status -1
      @execute
        cmd: """
        rm -Rf #{hbase.thrift.automake.tmp}
        mkdir #{hbase.thrift.automake.tmp}
        tar xzf #{hbase.thrift.automake.destination} -C #{hbase.thrift.automake.tmp} --strip-components=1
        cd #{hbase.thrift.automake.tmp}
        ./configure --prefix=/usr
        make && make install
        cd ..
        rm -Rf #{hbase.thrift.automake.destination}
        rm -Rf #{hbase.thrift.automake.tmp}
        """
        trap_on_error: true
        if: -> @status -2

## Thrift Bison

    module.exports.push name: 'Thrift # Install Bison', timeout: -1, handler: (options) ->
      {hbase} = @config.ryba
      options.log "Check if Bison is installed"
      @call (_, callback) ->
        @execute
          cmd: "bison --version | egrep '.*[0-9]\\.[0-9]\\.[0-9]' | awk '{ print $4 }'"
        , (err, executed, stdout) ->
          return callback err if err and err.code isnt 2
          stdout = '' if err
          bison_version =  stdout.toString('utf-8').trim()
          if bison_version ==  hbase.thrift.bison.version
            options.log "bison :already up to date version #{hbase.thrift.bison.version}"
            return callback null, false
          else
            options.log "bison : is not installed"
            callback null, true
      @download
        source: hbase.thrift.bison.url
        destination: hbase.thrift.bison.destination
        binary: true
      @execute
        cmd: """
        rm -Rf #{hbase.thrift.bison.tmp}
        mkdir #{hbase.thrift.bison.tmp}
        tar xzf #{hbase.thrift.bison.destination} -C #{hbase.thrift.bison.tmp} --strip-components=1
        cd #{hbase.thrift.bison.tmp}
        ./configure --prefix=/usr
        make && make install
        cd ..
        rm -Rf #{hbase.thrift.bison.destination}
        rm -Rf #{hbase.thrift.bison.tmp}
        """
        trap_on_error: true

## Thrift Thrift Compiler

    module.exports.push name: 'Thrift # Install Compiler', timeout: -1, handler: (options) ->
      {hbase} = @config.ryba
      # Check if Thrift Compiler is installed
      @call (_, callback) ->
        @execute
          cmd: "compiler --version | egrep '.*[0-9]\\.[0-9]\\.[0-9]' | awk '{ print $4 }'"
        , (err, executed, stdout) ->
          return callback err if err and err.code isnt 2
          stdout = '' if err
          compiler_version =  stdout.toString('utf-8').trim()
          if compiler_version ==  hbase.thrift.compiler.version
            options.log "compiler :already up to date version #{hbase.thrift.compiler.version}"
            callback null, false
          else
            callback null, true
      @download
        source: hbase.thrift.compiler.url
        destination: hbase.thrift.compiler.destination
        binary: true
      @execute
        cmd: """
        rm -Rf #{hbase.thrift.compiler.tmp}
        mkdir #{hbase.thrift.compiler.tmp}
        tar xzf #{hbase.thrift.compiler.destination} -C #{hbase.thrift.compiler.tmp} --strip-components=1
        cd #{hbase.thrift.compiler.tmp}
        ./configure --prefix=/usr
        make && make install
        cd ..
        rm -Rf #{hbase.thrift.compiler.destination}
        rm -Rf #{hbase.thrift.compiler.tmp}
        """
        trap_on_error: true

##  Hbase-Thrift Service

    module.exports.push name: 'HBase Thrift # Service', handler: ->
      {hbase} = @config.ryba
      @service
        name: 'hbase-thrift'
      @hdp_select
        name: 'hbase-client'
      @write
        source: "#{__dirname}/../resources/hbase-thrift"
        local_source: true
        destination: '/etc/init.d/hbase-thrift'
        mode: 0o0755
        unlink: true
      @execute
        cmd: "service hbase-thrift restart"
        if: -> @status -3

## Kerberos

    module.exports.push name: 'HBase Thrift # Kerberos', handler: ->
      {hadoop_group, hbase, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: hbase.site['hbase.thrift.kerberos.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: hbase.site['hbase.thrift.keytab.file']
        uid: hbase.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

## Configure

Note, we left the permission mode as default, Master and RegionServer need to
restrict it but not the thrift server.

    module.exports.push name: 'HBase Thrift # Configure', handler: ->
      {hbase} = @config.ryba
      @hconfigure
        destination: "#{hbase.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../resources/hbase-site.xml"
        local_default: true
        properties: hbase.site
        merge: true
        uid: hbase.user.name
        gid: hbase.group.name
        backup: true

## Dependecies

    url = require 'url'
