
exports.hdfs = (ctx, cmd) ->
  {security, hdfs, realm} = ctx.config.ryba
  if security is 'kerberos'
  then "echo #{hdfs.krb5_user.password} | kinit #{hdfs.krb5_user.name}@#{realm} >/dev/null && {\n#{cmd}\n}"
  else "su -l #{hdfs.user.name} -c \"#{cmd}\""
  # else "kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs && {\n#{cmd}\n}"

exports.test = (ctx, cmd) ->
  {security, test_user, test_password, realm} = ctx.config.ryba
  if security is 'kerberos'
  # then "kinit -kt /etc/security/keytabs/test.headless.keytab test && {\n#{cmd}\n}"
  then "echo #{test_password} | kinit #{test_user.name}@#{realm} >/dev/null && {\n#{cmd}\n}"
  else "su -l #{test_user.name} -c \"#{cmd}\""
