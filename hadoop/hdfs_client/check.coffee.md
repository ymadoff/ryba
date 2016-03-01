
# Hadoop HDFS Client Check

Check the access to the HDFS cluster.

    module.exports = header: 'HDFS Client Check', timeout: -1, label_true: 'CHECKED', handler: ->
      {core_site, user, krb5_user} = @config.ryba

Run an HDFS command requiring a NameNode.

      @wait_execute
        header: 'NameNode'
        label_true: 'CHECKED',
        cmd: mkcmd.test @, "hdfs dfs -test -d /user/#{user.name}"

Run an HDFS command requiring a DataNode.
      
      @execute
        header: 'DataNode'
        label_true: 'CHECKED',
        cmd: mkcmd.test @, """
        if hdfs dfs -test -f /user/#{user.name}/#{@config.host}-hdfs; then exit 2; fi
        hdfs dfs -touchz /user/#{user.name}/#{@config.host}-hdfs
        """
        code_skipped: 2

## Check Kerberos Mapping

Kerberos Mapping is configured in "core-site.xml" by the
"hadoop.security.auth_to_local" property. Hadoop provided a comman which take
the principal name as argument and print the converted user name.

      @execute
        header: 'Kerberos Mapping'
        label_true: 'CHECKED'
        cmd: "hadoop org.apache.hadoop.security.HadoopKerberosName #{krb5_user.principal}"
        if: core_site['hadoop.security.authentication'] is 'kerberos'
      , (err, _, stdout) ->
        throw Error "Invalid mapping" if not err and stdout.indexOf("#{krb5_user.principal} to #{user.name}") is -1

## Dependencies

    mkcmd = require '../../lib/mkcmd'
