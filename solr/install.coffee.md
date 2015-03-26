
# Solr Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/commons/java'
    module.exports.push require('./').configure


    module.exports.push name: 'Solr # Users & Groups', handler: (ctx, next) ->
      {solr} = ctx.config.ryba
      ctx.group solr.group, (err, gmodified) ->
        return next err if err
        ctx.user solr.user, (err, umodified) ->
          next err, gmodified or umodified

## Layout

    module.exports.push name: 'Solr # Layout', timeout: -1, handler: (ctx, next) ->
      {solr} = ctx.config.ryba
      ctx.mkdir [
        destination: solr.install_dir
      ,
        destination: solr.var_dir
        uid: solr.user.name
        gid: solr.group.name
        mode: 0o0755
      ,
        destination: solr.log_dir
        uid: solr.user.name
        gid: solr.group.name
        mode: 0o0755
      ], next

## Install

Solr archive comes with an install scripts which creates and sets directories, env vars & scripts.
Ryba execute this scripts then customize installation 

    module.exports.push name: 'Solr # Install', timeout: -1, handler: (ctx, next) ->
      {solr} = ctx.config.ryba
      archive_name = path.basename solr.source
      archive_path = path.join solr.install_dir, archive_name
      installer = path.join solr.install_dir, 'install_solr_service.sh'
      do_download = () ->
        ctx.log 'Downloading (if necessary)...'
        ctx.download
          source: solr.source
          destination: archive_path
        , (err, downloaded) ->
          return next err if err
          ctx.log if downloaded then 'Archive downloaded !' else 'Download skipped'
          do_extract()
      do_extract = () ->
        ctx.log 'Extracting install scripts...'
        ctx.execute
          cmd:"""
          cd #{solr.install_dir};
          tar xzf solr-#{solr.version}.tgz solr-#{solr.version}/bin/install_solr_service.sh --strip-components=2
          """
          not_if_exists: installer
        , (err, extracted) ->
          console.log "COUCOU: #{ctx.config.host}"
          return next err if err
          do_clean_script()
      # Deactivate start solr in install script !
      do_clean_script = () ->
        ctx.log 'Cleaning script...'      
        ctx.write
          destination: installer
          match: /\nservice \$SOLR_SERVICE start(.*)(\n*)status\n/m
          replace: '\n'
          if_exists: installer
        , (err, cleaned) ->
          return next err if err
          ctx.log if cleaned then 'Script cleaned !' else 'Script unchanged [WARN]'
          do_install()
      do_install = () ->
        ctx.execute
          cmd:"""
          bash #{installer} solr-#{solr.version}.tgz -i #{solr.install_dir} -d #{solr.var_dir} -u #{solr.user.name} -p #{solr.port}
          rm -f #{installer}
          #{solr.install_dir}/solr/server/scripts/cloud-scripts/zkcli.sh -zkhost "#{solr.zkhost}" -cmd bootstrap -solrhome #{solr.user.home}
          """
        , next
      do_download()

    module.exports.push name: 'Solr # Env', handler: (ctx, next) ->
      {solr, zookeeper} = ctx.config.ryba
      write = [
        match: /^SOLR_PID_DIR=.*/m
        replace: "SOLR_PID_DIR=#{solr.var_dir} # RYBA CONF `solr.var_dir`, DON'T OVERWRITE"
      ,
        match: /^SOLR_HOME=.*/m
        replace: "SOLR_HOME=#{solr.user.home} # RYBA CONF `solr.user.home`, DON'T OVERWRITE"
      ,
        match: /^LOG4J_PROPS=.*/m
        replace: "LOG4J_PROPS=#{path.join solr.var_dir, 'log4j.properties'} # RYBA CONF `solr.var_dir`/log4j.properties, DON'T OVERWRITE"
      ,
        match: /^SOLR_LOGS_DIR=.*/m
        replace: "SOLR_LOGS_DIR=#{solr.log_dir} # RYBA CONF `solr.log_dir`, DON'T OVERWRITE"
      ,
        match: /^SOLR_PORT=.*/m
        replace: "SOLR_PORT=#{solr.port} # RYBA CONF `solr.port`, DON'T OVERWRITE"
      ]
      if solr.mode is 'cloud'
        write.unshift
          match: /^SOLR_MODE=.*/m
          replace: "SOLR_MODE=solrcloud # RYBA CONF, DON'T OVERWRITE"
          before: /^(.*)ZK_HOST=.*/m
        write.unshift
          match: /^(.*)ZK_HOST=.*/m
          replace: "ZK_HOST=#{solr.zkhost} # RYBA CONF, DON'T OVERWRITE"
      ctx.write
        destination: path.join solr.var_dir, 'solr.in.sh'
        write: write
      , next

## Kerberos

    module.exports.push name: 'Solr # Kerberos', handler: (ctx, next) ->
      {solr, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: "solr/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: path.join solr.var_dir, 'solr.service.keytab'
        uid: solr.user.name
        gid: solr.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next


    module.exports.push name: 'Solr # Tuning', handler: (ctx, next) ->
      next null, 'TODO'

## Module Dependencies

    path = require 'path'