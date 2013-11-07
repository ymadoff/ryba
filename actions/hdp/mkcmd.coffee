
exports.hdfs = (ctx, cmd) ->
  {security, hdfs_user, hdfs_password} = ctx.config.hdp
  {realm} = ctx.config.krb5_client
  kerberos = ctx.hasAction('histi/actions/hdp_krb5')
  if security is 'kerberos'
  then "echo #{hdfs_password} | kinit hdfs@#{realm} >/dev/null && {\n#{cmd}\n}"
  else "su -l #{hdfs_user} -c \"#{cmd}\""
  # else "kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs && {\n#{cmd}\n}"

exports.test = (ctx, cmd) ->
  {test_user, test_password, security} = ctx.config.hdp
  {realm} = ctx.config.krb5_client
  kerberos = ctx.hasAction('histi/actions/hdp_krb5')
  if security is 'kerberos'
  # then "kinit -kt /etc/security/keytabs/test.headless.keytab test && {\n#{cmd}\n}"
  then "echo #{test_password} | kinit #{test_user}@#{realm} >/dev/null && {\n#{cmd}\n}"
  else "su -l #{test_user} -c \"#{cmd}\""
