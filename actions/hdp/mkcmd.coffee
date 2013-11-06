
exports.hdfs = (ctx, cmd) ->
  {hdfs_user, security} = ctx.config.hdp
  {realm} = ctx.config.krb5_client
  kerberos = ctx.hasAction('histi/actions/hdp_krb5')
  if security is 'kerberos'
  then "echo hdfs123 | kinit hdfs@#{realm} && {\n#{cmd}\n}"
  else "su -l #{hdfs_user} -c \"#{cmd}\""
  # else "kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs && {\n#{cmd}\n}"

exports.test = (ctx, cmd) ->
  {test_user, security} = ctx.config.hdp
  {realm} = ctx.config.krb5_client
  kerberos = ctx.hasAction('histi/actions/hdp_krb5')
  if security is 'kerberos'
  # then "kinit -kt /etc/security/keytabs/test.headless.keytab test && {\n#{cmd}\n}"
  then "echo test123 | kinit test@#{realm} && {\n#{cmd}\n}"
  else "su -l #{test_user} -c \"#{cmd}\""
