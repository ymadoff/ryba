

###

Options:

*   `password`   
*   `principal`   
*   `cmd`   
*   `name`   

Unix exemple

```
nikita.execute mkcmd
  name: 'ryba'
  cmd: 'hdfs dfs -ls'
```

Kerberos exemple

```
nikita.execute mkcmd
  principal: 'ryba'
  password: 'ryba123'
  cmd: 'hdfs dfs -ls'
```

###

# Options:
# - cmd
# - password, if security is "kerberos"
# - principal, if security is "kerberos"
# - name, if security isnt "kerberos"
module.exports = (args...) ->
  options = {}
  for opts in args
    if typeof opts is 'string'
      throw Error "Invalid mkcmd options: cmd already defined" if options.cmd
      options.cmd ?= opts
    options[k] = v for k, v of opts
  throw Error "Required Option: password is required if principal is provided" if options.principal and not options.password
  if options.principal
  then "echo '#{options.password}' | kinit #{options.principal} >/dev/null && {\n#{options.cmd}\n}"
  else "su -l #{options.name} -c \"#{options.cmd}\""
  # if options.principal
  # then "echo '#{options.password}' | kinit #{options.principal} >/dev/null && {\n#{options.cmd}\n}"
  # else "su -l #{options.name} -c \"#{options.cmd}\""

module.exports.hbase = (ctx, cmd) ->
  {security, hbase} = ctx.config.ryba
  if security is 'kerberos'
  then "echo '#{hbase.admin.password}' | kinit #{hbase.admin.principal} >/dev/null && {\n#{cmd}\n}"
  else "su -l #{hbase.user.name} -c \"#{cmd}\""

module.exports.hdfs = (ctx, cmd) ->
  {security, hdfs} = ctx.config.ryba
  if security is 'kerberos'
  then "echo '#{hdfs.krb5_user.password}' | kinit #{hdfs.krb5_user.principal} >/dev/null && {\n#{cmd}\n}"
  else "su -l #{hdfs.user.name} -c \"#{cmd}\""

module.exports.test = (ctx, cmd) ->
  {security, user, krb5_user} = ctx.config.ryba
  if security is 'kerberos'
  then "echo #{krb5_user.password} | kinit #{krb5_user.principal} >/dev/null && {\n#{cmd}\n}"
  else "su -l #{user.name} -c \"#{cmd}\""

module.exports.kafka = (ctx, cmd) ->
  {security, kafka} = ctx.config.ryba
  if security is 'kerberos'
  then "echo '#{kafka.admin.password}' | kinit #{kafka.admin.principal} >/dev/null && {\n#{cmd}\n}"
  else "su -l #{kafka.user.name} -c \"#{cmd}\""

module.exports.solr = (ctx, cmd) ->
  {security, solr} = ctx.config.ryba
  if security is 'kerberos'
  then "echo '#{solr.admin_password}' | kinit #{solr.admin_principal} >/dev/null && {\n#{cmd}\n}"
  else "su -l #{solr.user.name} -c \"#{cmd}\""
