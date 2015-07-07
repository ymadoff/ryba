
# Titan Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hbase/master/wait'
    module.exports.push require('./index').configure

## Check Configuration

Creates a configuration file. Always load this file in Gremlin REPL !
Check the configuration file (current.properties).

    module.exports.push name: 'Titan # Check Shell', label_true: 'CHECKED', handler: (ctx, next) ->
      {shortname} = ctx.config
      {force_check, hbase, titan} = ctx.config.ryba
      config = {}
      config[k] = v for k, v of titan.config
      config['storage.hbase.table'] = 'titan-test'
      check = false
      ctx
      .ini
        destination: path.join titan.home, "titan-#{titan.config['storage.backend']}-#{titan.config['index.search.backend']}-test.properties"
        content: config
        separator: '='
        merge: true
      .execute
        cmd: mkcmd.hbase ctx, """
        cd #{titan.home}
        #{titan.install_dir}/current/bin/gremlin.sh 2>/dev/null <<< \"g = TitanFactory.open('titan-hbase-#{titan.config['index.search.backend']}-test.properties')\" | grep '==>titangraph'
        hbase shell 2>/dev/null <<< "grant 'ryba', 'RWC', 'titan-test'"
        """
        not_if_exec: unless force_check then mkcmd.test ctx, "hbase shell 2>/dev/null <<< \"exists 'titan-test'\""
      , (err, status) ->
        check = true if status
      .execute
        cmd: mkcmd.test ctx, """
        cd #{titan.home}
        cmd="TitanFactory.open('titan-#{titan.config['storage.backend']}-#{titan.config['index.search.backend']}-test.properties')"
        #{titan.install_dir}/current/bin/gremlin.sh 2>/dev/null <<< "$cmd" | grep '==>titangraph'
        """
        if: -> check
      .then next

## Dependencies

    path = require 'path'
    mkcmd = require '../lib/mkcmd'
