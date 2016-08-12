
# DB Administration

    module.exports = handler: ->
        {ryba} = @config ?= {}
        # Database administration
        # todo: `require('masson/commons/mysql/server').configure ctx` and use returned values as default values
        ryba.db_admin ?= {}
        ryba.engine ?= ryba.db_admin.engine ?= 'mysql'
        switch ryba.db_admin.engine
          when 'mysql'
            unless ryba.db_admin.host
              mysql_ctxs = @contexts 'masson/commons/mysql/server' , require('masson/commons/mysql/server/configure').handler
              mysql_hosts = (mysql_ctxs).map( (ctx) -> ctx.config.host )
              throw new Error "Expect at least one server with action \"masson/commons/mysql/server\"" if mysql_hosts.length is 0
              mysql_host = ryba.db_admin.host = if mysql_hosts.length is 1 then mysql_hosts[0] else
                i = mysql_hosts.indexOf(@config.host)
                if i isnt -1 then mysql_hosts[i] else throw new Error "Failed to find a Mysql Server"
              mysql_conf = mysql_ctxs.filter( (ctx) -> ctx.config.host is mysql_host)[0].config.mysql.server
            ryba.db_admin.path ?= 'mysql'
            ryba.db_admin.port ?= '3306'
            ryba.db_admin.username ?= 'root'
            ryba.db_admin.password ?= mysql_conf.password
        throw new Error "Database engine not supported: #{ryba.engine}" unless ryba.engine.toUpperCase() in ['MYSQL','POSTGRESQL']
        # Discovers databases configurations
        mysql_ctxs = @contexts 'masson/commons/mysql/server' , require('masson/commons/mysql/server/configure').handler
        postgres_ctxs = @contexts 'masson/commons/postgres_server_docker' , require('masson/commons/postgres/server/configure').handler
        if mysql_ctxs.length > 0
          ryba.db_admin.mysql ?= {}
          mysql_hosts = (mysql_ctxs).map( (ctx) -> ctx.config.host )
          throw new Error "Expect at least one server with action \"masson/commons/mysql/server\"" if mysql_hosts.length is 0
          mysql_host = ryba.db_admin.mysql.host = if mysql_hosts.length is 1 then mysql_hosts[0] else
            i = mysql_hosts.indexOf(@config.host)
            if i isnt -1 then mysql_hosts[i] else throw new Error "Failed to find a Mysql Server"
          mysql_conf = mysql_ctxs.filter( (ctx) -> ctx.config.host is mysql_host)[0].config.mysql.server
          ryba.db_admin.mysql.path ?= 'mysql'
          ryba.db_admin.mysql.port ?= '3306'
          ryba.db_admin.mysql.username ?= 'root'
          ryba.db_admin.mysql.password ?= mysql_conf.password
        if postgres_ctxs.length > 0
          ryba.db_admin.postgres ?= {}
          postgres_hosts = (postgres_ctxs).map( (ctx) -> ctx.config.host )
          throw new Error "Expect at least one server with action \"masson/commons/postgres/server\"" if postgres_hosts.length is 0
          postgres_host = ryba.db_admin.postgres.host = if postgres_hosts.length is 1 then postgres_hosts[0] else
            i = postgres_hosts.indexOf(@config.host)
            if i isnt -1 then postgres_hosts[i] else throw new Error "Failed to find a Postgres Server"
          postgres_conf = postgres_ctxs.filter( (ctx) -> ctx.config.host is postgres_host)[0].config.postgres.server
          ryba.db_admin.postgres.port ?= '5432'
          ryba.db_admin.postgres.username ?= postgres_conf.user
          ryba.db_admin.postgres.password ?= postgres_conf.password
