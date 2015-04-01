
# Titan Install

Install titan archive. It contains scripts for:
*   the Gremlin REPL
*   the Rexster Server

Note: the archive contains the rexster server but it is not configured here,
please see ryba/rexster

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hbase/client'
    module.exports.push 'ryba/elasticsearch'
    module.exports.push require('./index').configure
    module.exports.push require '../lib/write_jaas'

## Install

Download and extract a ZIP Archive

    module.exports.push name: 'Titan # Install', timeout: -1, handler: (ctx, next) ->
      {titan} = ctx.config.ryba
      archive_name = path.basename titan.source
      unzip_dir = path.join titan.install_dir, path.basename archive_name, path.extname archive_name
      archive_path = path.join titan.install_dir, archive_name
      do_download = () ->
        ctx.log 'downloading (if necessary)...'
        ctx.download
          source: titan.source
          destination: archive_path
        , (err, downloaded) ->
          return next err if err
          unless downloaded
            ctx.log 'download skipped'
            return next null, false
          ctx.log 'Archive downloaded !'
          ctx.fs.exists unzip_dir, (err, exists) ->
            return next err if err
            if exists
              ctx.log 'Archive content already exists. Removing before continue'
              ctx.remove
                destination: unzip_dir
              , (err, removed) ->
                return next err if err
                do_extract()
            else do_extract()
      do_extract = () ->
        ctx.log 'Extracting...'
        ctx.extract
          source: archive_path,
          destination: titan.install_dir
        , (err, extracted) ->
          return next err if err
          if extracted
            ctx.log "Archive extracted, remove previous titan.home link"
            ctx.remove
              destination: titan.home
            , (err, removed) ->
              ctx.log "Link titan.home to #{archive_name}"
              ctx.link
                source: unzip_dir
                destination: titan.home
              , next
      ctx.fs.exists titan.install_dir, (err, exists) ->
        return next err if err
        if exists then return do_download()
        else ctx.mkdir titan.install_dir, (err, created) ->
          return next err if err or not created
          ctx.log 'Titan Installation directory created !'
          do_download()

## Env

Modify envvars in the gremlin scripts.

    module.exports.push name: 'Titan # Gremlin Env', handler: (ctx, next) ->
      {titan, hbase} = ctx.config.ryba
      write = [
        match: /^(.*)JAVA_OPTIONS="-Dlog4j.configuration=[^f].*/m
        replace: "    JAVA_OPTIONS=\"-Dlog4j.configuration=file:#{path.join titan.home, 'conf', 'log4j-gremlin.properties'}\" # RYBA CONF, DON'T OVERWRITE"
      ,
        match: /^(.*)-Djava.security.auth.login.config=.*/m
        replace: "    JAVA_OPTIONS=\"$JAVA_OPTIONS -Djava.security.auth.login.config=#{path.join titan.home, 'titan.jaas'}\" # RYBA CONF, DON'T OVERWRITE"
        append: /^(.*)-Dgremlin.mr.log4j.level=.*/m
      ,
        match: /^(.*)-Djava.library.path.*/m
        replace: "    JAVA_OPTIONS=\"$JAVA_OPTIONS -Djava.library.path=${HADOOP_HOME}/lib/native\" # RYBA CONF, DON'T OVERWRITE"
        append: /^(.*)-Dgremlin.mr.log4j.level=.*/m
      ]
      if titan.config['storage.backend'] is 'hbase' then write.unshift
        match: /^.*# RYBA CONF hbase-env, DON'T OVERWRITE/m
        replace: "CP=\"$CP:#{ctx.config.ryba.hbase.conf_dir}\" # RYBA CONF hbase-env, DON'T OVERWRITE"
        append: /^CP=`abs_path`.*/m
      ctx.write
        destination: path.join titan.home, 'bin/gremlin.sh'
        write: write
      , next

## Kerberos

Secure the Zookeeper connection with JAAS

    module.exports.push name: 'Titan # Gremlin Kerberos JAAS', handler: (ctx, next) ->
      {titan} = ctx.config.ryba
      ctx.write_jaas
        destination: path.join titan.home, 'titan.jaas'
        content: client: {}
        mode: 0o644
      , next

## Configure

Creates a configuration file. Always load this one in Gremlin REPL !

    module.exports.push name: 'Titan # Gremlin Properties', handler: (ctx, next) ->
      {titan} = ctx.config.ryba
      ctx.log 'Configure titan.properties'
      ctx.ini
        destination: path.join titan.home, 'titan.properties'
        content: titan.config
        separator: '='
        merge: true
      , next

## HBase Configuration

### HBase ACL

    module.exports.push name: 'Titan # Create HBase Namespace', handler: (ctx, next) ->
      return next() # NAMESPACE NOT YET FULLY SUPPORTED
      return next() unless ctx.config.ryba.titan.config['storage.backend'] is 'hbase'
      {titan, hbase, realm} = ctx.config.ryba
      ctx.execute
        cmd: """
        echo #{hbase.admin.password} | kinit #{hbase.admin.principal} >/dev/null && {
        if hbase shell 2>/dev/null <<< "list_namespace 'titan'" | grep '1 row(s)'; then exit 3; fi
        hbase shell 2>/dev/null <<< "create_namespace 'titan'"
        }
        """
        code_skipped: 3
      , next

## Module Dependencies

    path = require 'path'
