

###
Mysql Server
------------

###
mecano = require 'mecano'
each = require 'each'
actions = module.exports = []

###
Configure
---------
###
actions.push (ctx) ->
  ctx.config.mysql_server ?= {}
  ctx.config.mysql_server.sql_on_install ?= []
  ctx.config.mysql_server.sql_on_install = [ctx.config.mysql_server.sql_on_install] if typeof ctx.config.mysql_server.sql_on_install is 'string'
  ctx.config.mysql_server.current_password ?= ''
  ctx.config.mysql_server.password ?= ''
  ctx.config.mysql_server.remove_anonymous ?= true
  ctx.config.mysql_server.disallow_remote_root_login ?= false
  ctx.config.mysql_server.remove_test_db ?= true
  ctx.config.mysql_server.reload_privileges ?= true

###
Package
-------
Install the Mysql database server.
###
actions.push (ctx, next) ->
  @name 'Mysql Server # Package'
  @timeout -1
  {sql_on_install} = ctx.config.mysql_server
  ctx.service
    name: 'mysql-server'
    chk_name: 'mysqld'
    srv_name: 'mysqld'
    startup: '235'
    action: 'start'
  , (err, serviced) ->
    return next err if err
    return next null, ctx.PASS unless serviced
    escape = (text) ->
      return text.replace(/[\\"]/g, "\\$&")
    each(sql_on_install)
    .on 'item', (sql, next) ->
      cmd = "mysql -uroot -e \"#{escape sql}\""
      ctx.log "Execute: #{cmd}"
      ctx.execute cmd: cmd, (err) ->
        next err
    .on 'both', (err) ->
      next err, ctx.OK

###
Java Connector
--------------
Install the Mysql Java connector. The 
jar is available at "/usr/share/java/mysql-connector-java.jar".
###
actions.push (ctx, next) ->
  @name 'Mysql Server # Java Connector'
  @timeout -1
  ctx.service
    name: 'mysql-connector-java'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

###
Secure Installation
-------------------
/usr/bin/mysql_secure_installation (run as root after install).
  Enter current password for root (enter for none):
  Set root password? [Y/n] y
  >> big123
  Remove anonymous users? [Y/n] y
  Disallow root login remotely? [Y/n] n
  Remove test database and access to it? [Y/n] y
###
actions.push (ctx, next) ->
  @name 'Mysql Server # Secure'
  {current_password, password, remove_anonymous, disallow_remote_root_login, remove_test_db, reload_privileges} = ctx.config.mysql_server
  test_password = true
  modified = false
  ctx.ssh.shell (err, stream) ->
    stream.write '/usr/bin/mysql_secure_installation\n'
    data = ''
    error = null
    stream.on 'data', (data, extended) ->
      ctx.log[if extended is 'stderr' then 'err' else 'out'].write data
      switch
        when /Enter current password for root/.test data
          stream.write "#{if test_password then password else current_password}\n"
          data = ''
        when /ERROR 1045/.test(data) and test_password
          test_password = false
          modified = true
          data = ''
        when /Change the root password/.test data
          stream.write "y\n"
          data = ''
        when /Set root password/.test data
          stream.write "y\n"
          data = ''
        when /New password/.test(data) or /Re-enter new password/.test(data)
          stream.write "#{password}\n"
          data = ''
        when /Remove anonymous users/.test data
          stream.write "#{if remove_anonymous then 'y' else 'n'}\n"
          data = ''
        when /Disallow root login remotely/.test data
          stream.write "#{if disallow_remote_root_login then 'y' else 'n'}\n"
          data = ''
        when /Remove test database and access to it/.test data
          stream.write "#{if remove_test_db then 'y' else 'n'}\n"
          data = ''
        when /Reload privilege tables now/.test data
          stream.write "#{if reload_privileges then 'y' else 'n'}\n"
          data = ''
        when /All done/.test data
          stream.end()
        when /ERROR/.test data
          return if data.indexOf('ERROR 1008 (HY000) at line 1: Can\'t drop database \'test\'') isnt -1
          error = new Error data
          stream.end()
    stream.on 'close', ->
      next error, if modified then ctx.OK else ctx.PASS




