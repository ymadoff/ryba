
# DB Administration

    module.exports = handler: ->
        {ryba} = @config ?= {}
        # Database administration
        # todo: `require('masson/commons/mysql_server').configure ctx` and use returned values as default values
        ryba.db_admin ?= {}
        ryba.db_admin.engine ?= 'mysql'
        switch ryba.db_admin.engine
          when 'mysql'
            unless ryba.db_admin.host
              mysql_ctxs = @contexts 'masson/commons/mysql_server' , require('masson/commons/mysql_server/configure').handler
              mysql_hosts = (mysql_ctxs).map( (ctx) -> ctx.config.host )
              throw new Error "Expect at least one server with action \"masson/commons/mysql_server\"" if mysql_hosts.length is 0
              mysql_host = ryba.db_admin.host = if mysql_hosts.length is 1 then mysql_hosts[0] else
                i = mysql_hosts.indexOf(@config.host)
                if i isnt -1 then mysql_hosts[i] else throw new Error "Failed to find a Mysql Server"
              mysql_conf = mysql_ctxs.filter( (ctx) -> ctx.config.host is mysql_host)[0].config.mysql.server
            ryba.db_admin.path ?= 'mysql'
            ryba.db_admin.port ?= '3306'
            ryba.db_admin.username ?= 'root'
            ryba.db_admin.password ?= mysql_conf.password


          else throw new Error "Database engine not supported: #{ryba.engine}"
