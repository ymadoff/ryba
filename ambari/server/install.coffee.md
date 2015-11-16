
# Ambari Server Install

    # util = require 'util'
    # misc = require 'mecano/lib/misc'
    # each = require 'each'
    # ini = require 'ini'
    # url = require 'url'
    # builder = require 'xmlbuilder'
     
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/commons/java'
    module.exports.push 'masson/commons/mysql_client'
    # module.exports.push require('./index').configure
 
See the documentation about [Software Requirements][sr].

## Package

Install Ambari server package.

    module.exports.push header: 'Ambari Server # Package', timeout: -1, handler: ->
      @service
        name: 'ambari-server'
        startup: true

## Repository

Declare the Ambari custom repository.

    module.exports.push header: 'Ambari Server # Repo', handler: ->
      {ambari_server} = @config.ryba
      @download
        source: ambari_server.repo
        destination: '/etc/yum.repos.d/ambari.repo'
      @execute
        cmd: "yum clean metadata; yum update -y"
        if: -> @status -1

## Database

Prepare the Ambari Database

    module.exports.push header: 'Ambari Server # Database', handler: ->
      {ambari_server, db_admin} = @config.ryba
      mysql_exec = "#{db_admin.path} -u#{db_admin.username} -p#{db_admin.password} -h#{db_admin.host} -P#{db_admin.port} "
      db =
        name: ambari_server.config['server.jdbc.database_name']
        user: ambari_server.config['server.jdbc.user.name']
        password: ambari_server.database_password

Password is stored inside a file which location is referenced by the property
"server.jdbc.user.passwd" in the configuration file.

      @write
        destination: ambari_server.config['server.jdbc.user.passwd']
        content: ambari_server.database_password
        backup: true
        mode: 0o0660

Create the database hosting the Ambari data with restrictive user permissions.

      @execute
        cmd: """
        #{mysql_exec} -e "
        create database #{db.name};
        grant all privileges on #{db.name}.* to '#{db.user}'@'localhost' identified by '#{db.password}';
        grant all privileges on #{db.name}.* to '#{db.user}'@'%' identified by '#{db.password}';
        flush privileges;
        "
        """
        unless_exec: "#{mysql_exec} -e 'use #{db.name}'"

Load the database with initial data

      @execute
        cmd: """
        #{mysql_exec} #{db.name} < /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql
        """
        if_exec: "[ `#{mysql_exec} -B -N -e 'use #{db.name}; show tables' | wc -l` == '0' ]"
 
## Configuration

Merge used defined configuration. This could be used to set up 
LDAP or Active Directory Authentication.

    module.exports.push header: 'Ambari Server # Config', ->
      {ambari_server, db_admin} = @config.ryba
      db =
        name: ambari_server.config['server.jdbc.database_name']
        user: ambari_server.config['server.jdbc.user.name']
        password: ambari_server.database_password
      @ini
        destination: "#{ambari_server.conf_dir}/ambari.properties"
        content: ambari_server.config
        merge: true
        backup: true
      @execute
        cmd: """
        ambari-server setup \
          -s \
          -j #{ambari_server.java_home} \
          --database=mysql \
          --databasehost=#{db_admin.host} \
          --databaseport=#{db_admin.port} \
          --databasename=#{db.name} \
          --databaseusername=#{db.user} \
          --databasepassword=#{db.password} \
          --cluster-name=#{@config.cluster.name}
        """
