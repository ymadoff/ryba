
# Hadoop HDFS Client Check

Check the access to the HDFS cluster.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_dn/wait'
    module.exports.push require('./index').configure

    module.exports.push name: 'HDFS Client # Check', timeout: -1, label_true: 'CHECKED', handler: (ctx, next) ->
      {hadoop_conf_dir, hdfs, user} = ctx.config.ryba
      ctx.waitForExecution mkcmd.test(ctx, "hdfs dfs -test -d /user/#{user.name}"), (err) ->
        return next err if err
        ctx.execute
          cmd: mkcmd.test ctx, """
          if hdfs dfs -test -f /user/#{user.name}/#{ctx.config.host}-hdfs; then exit 2; fi
          hdfs dfs -touchz /user/#{user.name}/#{ctx.config.host}-hdfs
          """
          code_skipped: 2
        .then next

## Check Kerberos Mapping

Kerberos Mapping is configured in "core-site.xml" by the
"hadoop.security.auth_to_local" property. Hadoop provided a comman which take
the principal name as argument and print the converted user name.

    module.exports.push name: 'Hadoop Core # Check Kerberos Mapping', label_true: 'CHECKED', handler: (ctx, next) ->
      {core_site, user, krb5_user, realm} = ctx.config.ryba
      ctx.execute
        cmd: "hadoop org.apache.hadoop.security.HadoopKerberosName #{krb5_user.name}@#{realm}"
        if: core_site['hadoop.security.authentication'] is 'kerberos'
      , (err, _, stdout) ->
        throw Error "Invalid mapping" if not err and stdout.indexOf("#{krb5_user.name}@#{realm} to #{user.name}") is -1
      .then next

## Dependencies

    mkcmd = require '../../lib/mkcmd'
