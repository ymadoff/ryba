
# HBASE Master Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./master').configure ctx

## Shell

Create a "ryba" namespace and set full permission to the "ryba" user. This
namespace is used by other modules as a testing environment.

Namespace and permissions are implemented and illustrated in [HBASE-8409].

    module.exports.push name: 'HBASE Master Check # Shell', timeout:-1, callback: (ctx, next) ->
      {hbase_site} = ctx.config.ryba
      keytab = hbase_site['hbase.master.keytab.file']
      principal = hbase_site['hbase.master.kerberos.principal'].replace '_HOST', ctx.config.host
      ctx.execute
        cmd: """
        kinit -kt #{keytab} #{principal}
        if hbase shell 2>/dev/null <<< "user_permission 'ryba'" | egrep '[0-9]+ row'; then exit 2; fi
        hbase shell 2>/dev/null <<-CMD
          create 'ryba', 'family1'
          grant 'ryba', 'RWC', 'ryba'
        CMD
        """
        code_skipped: 2
      , (err, executed, stdout) ->
        hasCreatedTable = /create 'ryba', 'family1'\n0 row/.test stdout
        hasGrantedAccess = /grant 'ryba', 'RWC', 'ryba'\n0 row/.test stdout
        return next Error 'Invalid command output' if executed and ( not hasCreatedTable or not hasGrantedAccess)
        next err, if executed then ctx.OK else ctx.PASS
      # Note: inspiration this when namespace are functional
      # ctx.execute
      #   cmd: """
      #   kinit -kt #{keytab} #{principal}
      #   if hbase shell 2>/dev/null <<< "list_namespace_tables 'ryba'" | egrep '[0-9]+ row'; then exit 2; fi
      #   hbase shell 2>/dev/null <<-CMD
      #     create_namespace 'ryba'
      #     grant 'ryba', 'RWC', '@ryba'
      #   CMD
      #   """
      #   code_skipped: 2
      # , (err, executed, stdout) ->
      #   hasCreatedNamespace = /create_namespace 'ryba'\n0 row/.test stdout
      #   hasGrantedAccess = /grant 'ryba', 'RWC', '@ryba'\n0 row/.test stdout
      #   return next Error 'Invalid command output' if executed and ( not hasCreatedNamespace or not hasGrantedAccess)
      #   next err, if executed then ctx.OK else ctx.PASS


