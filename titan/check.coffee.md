
# Titan Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hbase/master/wait'
    module.exports.push require('./index').configure

## Check Configuration

Check the configuration file (current.properties)

    module.exports.push name: 'Titan # Check Shell', label_true: 'CHECKED', handler: (ctx, next) ->
      {shortname} = ctx.config
      {titan} = ctx.config.ryba
      cmd = "#{titan.install_dir}/current/bin/gremlin.sh 2>/dev/null <<< \"g = TitanFactory.open('titan-#{titan.config['storage.backend']}-#{titan.config['index.search.backend']}-test.properties')\""
      ctx.execute
        cmd: mkcmd.test ctx, """
          cd #{titan.home}
          #{cmd} | grep '==>titangraph'
        """
      , (err, executed, stdout) ->
          next err, executed

## Module Dependencies

    mkcmd = require '../lib/mkcmd'
