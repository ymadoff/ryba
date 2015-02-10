
# HBASE Master Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./master').configure

## Check SPNEGO

Check if keytab file exists and if read permission is granted to the HBase user.

Note: The Master webapp located in "/usr/lib/hbase/hbase-webapps/master" is
using the hadoop conf directory to retrieve the SPNEGO keytab. The user "hbase"
is added membership to the group hadoop to gain read access.

    module.exports.push name: 'HBase Master # Check SPNEGO', label_true: 'CHECKED', handler: (ctx, next) ->
      {core_site, hbase} = ctx.config.ryba
      ctx.execute
        cmd: "su -l #{hbase.user.name} -c 'test -r #{core_site['hadoop.http.authentication.kerberos.keytab']}'"
      , next

# ## Shell

# NOTE: THIS WAS MOVED TO REGIONSEVER_CHECK
# To create an HBase table, at least one regionserver must be registered.

# Create a "ryba" namespace and set full permission to the "ryba" user. This
# namespace is used by other modules as a testing environment.

# Namespace and permissions are implemented and illustrated in [HBASE-8409].

#     module.exports.push name: 'HBase Master Check # Shell', timeout:-1, label_true: 'CHECKED', handler: (ctx, next) ->
#       {hbase} = ctx.config.ryba
#       keytab = hbase.site['hbase.master.keytab.file']
#       principal = hbase.site['hbase.master.kerberos.principal'].replace '_HOST', ctx.config.host
#       ctx.execute
#         cmd: """
#         kinit -kt #{keytab} #{principal}
#         if hbase shell 2>/dev/null <<< "user_permission 'ryba'" | egrep '[0-9]+ row'; then exit 2; fi
#         hbase shell 2>/dev/null <<-CMD
#           create 'ryba', 'family1'
#           grant 'ryba', 'RWC', 'ryba'
#         CMD
#         """
#         code_skipped: 2
#       , (err, executed, stdout) ->
#         hasCreatedTable = /create 'ryba', 'family1'\n0 row/.test stdout
#         hasGrantedAccess = /grant 'ryba', 'RWC', 'ryba'\n0 row/.test stdout
#         return next Error 'Invalid command output' if executed and ( not hasCreatedTable or not hasGrantedAccess)
#         next err, executed
#       # Note: apply this when namespace are functional
#       # ctx.execute
#       #   cmd: """
#       #   kinit -kt #{keytab} #{principal}
#       #   if hbase shell 2>/dev/null <<< "list_namespace_tables 'ryba'" | egrep '[0-9]+ row'; then exit 2; fi
#       #   hbase shell 2>/dev/null <<-CMD
#       #     create_namespace 'ryba'
#       #     grant 'ryba', 'RWC', '@ryba'
#       #   CMD
#       #   """
#       #   code_skipped: 2
#       # , (err, executed, stdout) ->
#       #   hasCreatedNamespace = /create_namespace 'ryba'\n0 row/.test stdout
#       #   hasGrantedAccess = /grant 'ryba', 'RWC', '@ryba'\n0 row/.test stdout
#       #   return next Error 'Invalid command output' if executed and ( not hasCreatedNamespace or not hasGrantedAccess)
#       #   next err, executed

# [HBASE-8409]: https://issues.apache.org/jira/browse/HBASE-8409
