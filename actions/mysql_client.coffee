
###
Mysql
=====
Install the MySQL command-line tool.
###
mecano = require 'mecano'
actions = module.exports = []

###
Package
-------
Install the Mysql client.
###
actions.push (ctx, next) ->
  @name 'Mysql # Package'
  ctx.service
    name: 'mysql'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

###
Connector
---------
Install the Mysql JDBC driver.
###
actions.push (ctx, next) ->
  # todo: below doesnt declare the mysql jar inside the hive lib folder
  # /usr/share/java/mysql-connector-java.jar
  @name 'Mysql # Connector'
  @timeout -1
  ctx.service
    name: 'mysql-connector-java'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS



