
# DB Administration
Configure `ryba.db_admin` based on cluster's topology. Ryba configured differents
components from this object. It must be provided if you use an external database
mysql or postgres


Example:
```
  ryba.db_admin:
    mysql:
      engine: 'mysql'
      hosts: ['master1.ryba','master2.ryba']
      port: '3306'
      admin_username: 'test'
      admin_password: 'test123'
      path: 'mysql'
      jdbc: 'jdbc:mysql://master1.ryba:3306,master2.ryba:3306'
    postgres:
      engine: 'postgres'
      hosts: ['master1.ryba','master2.ryba']
      port: '3306'
      admin_username: 'test'
      admin_password: 'test123'
      path: 'mysql'
      jdbc: 'jdbc:postgresql://master1.ryba:3306,master2.ryba:3306'
```

If external database is used, mandatory properties should be hosts,
admin\_username and admin\_password.
`ryba/commons/db_admin` constructs the jdbc_url.

`host` is also generated in the final object for legacy compatibility. If the administrators
set it hosts will be constructed on it.

## Source Code

    module.exports =
      use:
        mysql: 'masson/commons/mysql/server'
        postres: 'masson/commons/postgres/server'
      configure: ->
        {ryba} = @config ?= {}
        ryba.db_admin ?= {}
        ryba.engine ?= ryba.db_admin.engine ?= 'mysql'
        # Discovers databases configurations
        mysql_ctxs = @contexts 'masson/commons/mysql/server'
        postgres_ctxs = @contexts 'masson/commons/postgres/server'
        ryba.db_admin.mysql ?= {}
        ryba.db_admin.mysql.engine = 'mysql'
        mysql_hosts = ryba.db_admin.mysql.hosts ?= mysql_ctxs.map (ctx) -> ctx.config.host
        #backward compatibility with only host property
        if ryba.db_admin.mysql.host?
          mysql_hosts = ["#{ryba.db_admin.mysql.host}"]
        if mysql_hosts.length > 0
          ryba.db_admin.mysql.hosts ?= mysql_hosts
          ryba.db_admin.mysql.host ?= mysql_hosts[0]
          mysql_host = ryba.db_admin.mysql.host ?= mysql_hosts[0]
          ryba.db_admin.mysql.path ?= 'mysql'
          ryba.db_admin.mysql.engine ?= 'mysql'
          cluster_servers = mysql_ctxs.filter( (ctx) -> ctx.config.host in mysql_hosts)
          if cluster_servers.length > 0
            mysql_conf = mysql_ctxs[0].config.mysql.server
            ryba.db_admin.mysql.admin_username ?= 'root'
            ryba.db_admin.mysql.admin_password ?= mysql_conf.password
            ryba.db_admin.mysql.port ?= mysql_conf.my_cnf['mysqld']['port']
          else
            ryba.db_admin.mysql.port ?= '3306'
            throw Error 'admin_username must be provided for external mysql cluster' unless ryba.db_admin.mysql.admin_username?
            throw Error 'admin_password must be provided for external mysql cluster' unless ryba.db_admin.mysql.admin_password?
          url = mysql_hosts.map((host)-> "#{host}:#{ryba.db_admin.mysql.port}").join(',')
          ryba.db_admin.mysql.jdbc ?= "jdbc:mysql://#{url}"
        # Configuring postgres part
        ryba.db_admin.postgres ?= {}
        ryba.db_admin.postgres.engine = 'postgres'
        postgres_hosts = ryba.db_admin.postgres.hosts ?= postgres_ctxs.map (ctx) -> ctx.config.host
        #backward compatibility with only host property
        if ryba.db_admin.postgres.host?
          postgres_hosts = ["#{ryba.db_admin.mysql.host}"]
        if postgres_hosts.length > 0
          ryba.db_admin.postgres.hosts ?= postgres_hosts
          ryba.db_admin.postgres.host ?= postgres_hosts[0]
          postgres_host = ryba.db_admin.postgres.host ?= postgres_hosts[0]
          ryba.db_admin.postgres.path ?= 'postgres'
          ryba.db_admin.postgres.engine ?= 'postgres'
          cluster_servers = postgres_ctxs.filter( (ctx) -> ctx.config.host in postgres_hosts)
          if cluster_servers.length > 0
            postgres_conf = postgres_ctxs[0].config.postgres.server
            ryba.db_admin.postgres.admin_username ?= 'root'
            ryba.db_admin.postgres.admin_password ?= postgres_conf.password
            ryba.db_admin.postgres.port ?= postgres_conf.port
          else
            ryba.db_admin.postgres.port ?= '5432'
            throw Error 'admin_username must be provided for external mysql cluster' unless ryba.db_admin.postgres.admin_username?
            throw Error 'admin_password must be provided for external mysql cluster' unless ryba.db_admin.postgres.admin_password?
          url = postgres_hosts.map((host)-> "#{host}:#{ryba.db_admin.postgres.port}").join(',')
          ryba.db_admin.postgres.jdbc ?= "jdbc:postgresql://#{url}"
