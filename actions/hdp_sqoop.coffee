
path = require 'path'

module.exports = []
module.exports.push 'histi/actions/mysql_client'

module.exports.push (ctx) ->
  require('./hdp_core').configure ctx
  ctx.config.hdp_sqoop ?= {}
  ctx.config.hdp_sqoop.libs ?= []

###
Install
-------
Visit the [install the Sqoop RPMs](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3/bk_installing_manually_book/content/rpm-chap10-1.html)
page for instructions.
###
module.exports.push (ctx, next) ->
  @name 'HDP Sqoop # Install'
  @timeout -1
  ctx.service
    name: 'sqoop'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS


module.exports.push (ctx, next) ->
  @name 'HDP Sqoop # Mysql Connector'
  ctx.copy
    source: '/usr/share/java/mysql-connector-java.jar'
    destination: '/usr/lib/sqoop/lib/'
  , (err, copied) ->
    return next err, if copied then ctx.OK else ctx.PASS

###
Libs
----
Upload all the driver present in the `hdp_sqoop.libs` configuration 
array. Visit the ["download database connector"](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3/bk_installing_manually_book/content/rpm-chap10-2.html) 
page for instructions.
###
module.exports.push (ctx, next) ->
  {libs} = ctx.config.hdp_sqoop
  return next() unless libs.length
  @timeout -1
  @name 'HDP Sqoop # Database Connector'
  uploads = for lib in libs
    source: lib
    destination: "/usr/lib/sqoop/lib/#{path.basename lib}"
    binary: true
  ctx.upload uploads, (err, uploaded) ->
    next err, if uploaded then ctx.OK else ctx.PASS

# Todo
# *   [Set Up the Sqoop Configuration](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3/bk_installing_manually_book/content/rpm-chap10-3.html)
# *   [Validate the Installation](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3/bk_installing_manually_book/content/rpm-chap10-4.html)







