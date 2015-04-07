# HBase Thrift Server

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/hadoop/core'
    module.exports.push 'ryba/hbase/_'
    module.exports.push require('./index').configure
    url = require 'url'

## IPTables

| Service                    | Port | Proto | Info                   |
|----------------------------|------|-------|------------------------|
| HBase Thrift Server        | 9090 | http  | hbase.thrift.port      |
| HBase Thrift Server Web UI | 9095 | http  | hbase.thrift.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'HBase Thrift # IPTables', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.rest.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Thrift Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.rest.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Thrift Info Web UI" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

###
DONE: Dependecies for thrift which are Autoconf - Automake - Bison
Wait: checkinf i the version given by the os are the needed one
Currently centos give Autoconf 2.63 - Automake 1.11 - Bison 2.4.1
Needed for thrift     Autoconf 2.69 - Automake 1.14 - Bison 2.5    
TODO: Installing Thrift Compiler
## Thrift Autoconf 

    module.exports.push name: 'Thrift # Install Autoconf', timeout: -1, handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.log "Check if Autoconf is installed "
      ctx.execute
        cmd: "autoconf --version | egrep '.*[0-9]\\.[0-9]{2}' | awk '{ print $4 }'"
      , (err, executed, stdout) ->
        return next err if err and err.code isnt 2
        stdout = '' if err
        autoconf_version =  stdout.toString('utf-8').trim()
        if autoconf_version ==  hbase.thrift.autoconf.version
          ctx.log "autoconf :already up to date version #{hbase.thrift.autoconf.version}"
          return next null, false
        else  
          action = if url.parse(hbase.thrift.autoconf.url).protocol is 'http:' then 'download' else 'upload'
          ctx.log "autoconf : is not installed "
          ctx[action]
                      source: hbase.thrift.autoconf.url
                      destination: hbase.thrift.autoconf.destination
                      binary: true
          , (err, downloaded) ->
            return next err if err
            ctx.log "autoconf : preparing for installation "
            ctx.execute
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
            , (err, executed, stdout) ->
              return next err, true

## Thrift Automake 

    module.exports.push name: 'Thrift # Install Automake', timeout: -1, handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.log "Check if Automake is installed "
      ctx.execute
        cmd: "automake --version | egrep '.*[0-9]\\.[0-9]{2}' | awk '{ print $4 }'"
      , (err, executed, stdout) ->
        return next err if err and err.code isnt 2
        stdout = '' if err
        automake_version =  stdout.toString('utf-8').trim()
        if automake_version ==  hbase.thrift.automake.version 
          ctx.log "automake :already up to date version #{hbase.thrift.automake.version}"
          return next null, false
        action = if url.parse(hbase.thrift.automake.url).protocol is 'http:' then 'download' else 'upload'
        ctx.log "automake : is not installed "
        ctx[action]
                    source: hbase.thrift.automake.url
                    destination: hbase.thrift.automake.destination
                    binary: true
        , (err, downloaded) ->
          return next err if err
          ctx.log "automake : preparing for installation "
          ctx.execute
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
          , (err, executed, stdout) ->
            return next err, true

## Thrift Bison 

    module.exports.push name: 'Thrift # Install Bison', timeout: -1, handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.log "Check if Bison is installed "
      ctx.execute
        cmd: "bison --version | egrep '.*[0-9]\\.[0-9]\\.[0-9]' | awk '{ print $4 }'"
      , (err, executed, stdout) ->
        return next err if err and err.code isnt 2
        stdout = '' if err
        bison_version =  stdout.toString('utf-8').trim()
        if bison_version ==  hbase.thrift.bison.version 
          ctx.log "bison :already up to date version #{hbase.thrift.bison.version}"
          return next null, false
        action = if url.parse(hbase.thrift.bison.url).protocol is 'http:' then 'download' else 'upload'
        ctx.log "bison : is not installed "
        ctx[action]
                    source: hbase.thrift.bison.url
                    destination: hbase.thrift.bison.destination
                    binary: true
        , (err, downloaded) ->
          return next err if err
          ctx.log "bison : preparing for installation "
          ctx.execute
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
          , (err, executed, stdout) ->
            return next err, true

## Thrift Thrift Compiler 

    module.exports.push name: 'Thrift # Install Compiler', timeout: -1, handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.log "Check if the Thrift Compiler is installed "
      ctx.execute
        cmd: "compiler --version | egrep '.*[0-9]\\.[0-9]\\.[0-9]' | awk '{ print $4 }'"
      , (err, executed, stdout) ->
        return next err if err and err.code isnt 2
        stdout = '' if err
        compiler_version =  stdout.toString('utf-8').trim()
        if compiler_version ==  hbase.thrift.compiler.version 
          ctx.log "compiler :already up to date version #{hbase.thrift.compiler.version}"
          return next null, false
        action = if url.parse(hbase.thrift.compiler.url).protocol is 'http:' then 'download' else 'upload'
        ctx.log "compiler : is not installed "
        ctx[action]
                    source: hbase.thrift.compiler.url
                    destination: hbase.thrift.compiler.destination
                    binary: true
        , (err, downloaded) ->
          return next err if err
          ctx.log "compiler : preparing for installation "
          ctx.execute
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
          , (err, executed, stdout) ->
            return next err, true
###



##  Hbase-Thrift Service

    module.exports.push name: 'HBase Thrift # Service', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.service
        name: 'hbase-thrift'
      , next

## Kerberos

    module.exports.push name: 'HBase Thrift # Kerberos', handler: (ctx, next) ->
      {hadoop_group, hbase, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: hbase.site['hbase.thrift.kerberos.principal'].replace '_HOST', ctx.config.host
        randkey: true
        keytab: hbase.site['hbase.thrift.keytab.file']
        uid: hbase.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

## Configure

Note, we left the permission mode as default, Master and RegionServer need to
restrict it but not the rest server.

    module.exports.push name: 'HBase Thrift # Configure', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hbase.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../../resources/hbase/hbase-site.xml"
        local_default: true
        properties: hbase.site
        merge: true
        uid: hbase.user.name
        gid: hbase.group.name
        backup: true
      , next

