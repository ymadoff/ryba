
# HBASE Master Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./index').configure

## Check SPNEGO

Check if keytab file exists and if read permission is granted to the HBase user.

Note: The Master webapp located in "/usr/lib/hbase/hbase-webapps/master" is
using the hadoop conf directory to retrieve the SPNEGO keytab. The user "hbase"
is added membership to the group hadoop to gain read access.

    module.exports.push name: 'HBase Master # Check SPNEGO', label_true: 'CHECKED', handler: (ctx, next) ->
      {core_site, hbase} = ctx.config.ryba
      ctx.execute
        cmd: "su -l #{hbase.user.name} -c 'test -r #{core_site['hadoop.http.authentication.kerberos.keytab']}'"
      .then next

