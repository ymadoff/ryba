
# Titan Install

Install titan archive. It contains scripts for:
*   the Gremlin REPL
*   the Rexster Server

Note: the archive contains the rexster server but it is not configured here,
please see ryba/rexster

    module.exports = header: 'Titan Install', timeout: -1, handler: ->
      {titan, hbase} = @config.ryba
      
## Install

Download and extract a ZIP Archive

      @call header: 'Packages', timeout: -1, handler: ->
        archive_name = path.basename titan.source
        unzip_dir = path.join titan.install_dir, path.basename archive_name, path.extname archive_name
        archive_path = path.join titan.install_dir, archive_name
        @mkdir
          destination: titan.install_dir
        @download
          source: titan.source
          destination: archive_path
        @remove
          destination: unzip_dir
          if: -> @status -1
        @extract
          source: archive_path,
          destination: titan.install_dir
        @remove
          destination: titan.home
          if: -> @status -1
        @link
          source: unzip_dir
          destination: titan.home
          if: -> @status -2

## Env

Modify envvars in the gremlin scripts.

      @call header: 'Gremlin Env', handler: ->
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
        ,
          match: /^(.*)# RYBA SET HADOOP-ENV, DON'T OVERWRITE/m
          replace: "HADOOP_HOME=/usr/hdp/current/hadoop-client # RYBA SET HADOOP-ENV, DON'T OVERWRITE"
          before: /^CP=`abs_path`.*/m
        ]
        if titan.config['storage.backend'] is 'hbase' then write.unshift
          match: /^.*# RYBA CONF hbase-env, DON'T OVERWRITE/m
          replace: "CP=\"$CP:#{@config.ryba.hbase.conf_dir}\" # RYBA CONF hbase-env, DON'T OVERWRITE"
          append: /^CP=`abs_path`.*/m
        @write
          destination: path.join titan.home, 'bin/gremlin.sh'
          write: write

## Kerberos

Secure the Zookeeper connection with JAAS

      @write_jaas
        header: 'Kerberos JAAS'
        destination: path.join titan.home, 'titan.jaas'
        content: Client:
          useTicketCache: 'true'
        mode: 0o644

## Configure

Creates a configuration file. Always load this file in Gremlin REPL !

      @call header: 'Gremlin Properties', handler: ->
        storage = titan.config['storage.backend']
        index = titan.config['index.search.backend']
        @ini
          destination: path.join titan.home, "titan-#{storage}-#{index}.properties"
          content: titan.config
          separator: '='
          merge: true

# ## Configure Test

# Creates a configuration file. Always load this file in Gremlin REPL !

#     module.exports.push header: 'Titan # Gremlin Test Properties', handler: ->
#       {titan} = @config.ryba
#       storage = titan.config['storage.backend']
#       config = {}
#       config[k] = v for k, v of titan.config
#       config['storage.hbase.table'] = 'titan-test'
#       @ini
#         destination: path.join titan.home, "titan-hbase-#{titan.config['index.search.backend']}-test.properties"
#         content: config
#         separator: '='
#         merge: true

## HBase Configuration

      @call
        skip: true, header: 'Create HBase Namespace'
        if: -> @config.ryba.titan.config['storage.backend'] is 'hbase'
        handler: (options) ->
          return
          options.log "Titan: HBase namespace not yet ready"
          @execute
            cmd: mkcmd.hbase @, """
            if hbase shell -n 2>/dev/null <<< "list_namespace 'titan'" | grep '1 row(s)'; then exit 3; fi
            hbase shell -n 2>/dev/null <<< "create_namespace 'titan'"
            """
            code_skipped: 3

      @call
        header: 'Create HBase table'
        if: -> @config.ryba.titan.config['storage.backend'] is 'hbase'
        handler: ->
          return
          table = titan.config['storage.hbase.table']
          @execute
            cmd: mkcmd.hbase @, """
            if hbase shell -n 2>/dev/null <<< "exists '#{table}'" | grep 'Table #{table} does exist'; then exit 3; fi
            cd #{titan.home}
            #{titan.install_dir}/current/bin/gremlin.sh 2>/dev/null <<< \"g = TitanFactory.open('titan-hbase-#{titan.config['index.search.backend']}.properties')\" | grep '==>titangraph'
            """
            code_skipped: 3

    # module.exports.push header: 'Titan # Create HBase test table', handler: ->
    #   return next() unless @config.ryba.titan.config['storage.backend'] is 'hbase'
    #   {titan, hbase} = @config.ryba
    #   @execute
    #     cmd: mkcmd.hbase @, """
    #     if hbase shell 2>/dev/null <<< "exists 'titan-test'" | grep 'Table titan-test does exist'; then exit 3; fi
    #     cd #{titan.home}
    #     #{titan.install_dir}/current/bin/gremlin.sh 2>/dev/null <<< \"g = TitanFactory.open('titan-hbase-#{titan.config['index.search.backend']}-test.properties')\" | grep '==>titangraph'
    #     """
    #     code_skipped: 3
    #   @execute
    #     cmd: mkcmd.hbase @, """
    #     if hbase shell 2>/dev/null <<< "user_permission 'titan-test'" | grep 'ryba'; then exit 3; fi
    #     hbase shell 2>/dev/null <<< "grant 'ryba', 'RWC', 'titan-test'"
    #     """
    #     code_skipped: 3

## Dependencies

    path = require 'path'
    mkcmd = require '../lib/mkcmd'
