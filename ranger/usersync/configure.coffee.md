
# Configure

    module.exports = handler: ->
      {ryba} = @config
      {ssl, ssl_client} = ryba ?= {}
      ranger = @config.ryba.ranger ?= {}
      [ranger_admin_ctx] = (@contexts 'ryba/ranger/admin',[ require('../../commons/db_admin').handler, require('../admin/configure').handler ])
      return throw new Error 'Needs Ranger Admin service' unless ranger_admin_ctx
      # Group
      ranger.group = name: ranger.group if typeof ranger.group is 'string'
      ranger.group ?= {}
      ranger.group.name ?= 'ranger'
      ranger.group.system ?= true
      # User
      ranger.user ?= {}
      ranger.user = name: ranger.user if typeof ranger.user is 'string'
      ranger.user.name ?= ranger.group.name
      ranger.user.system ?= true
      ranger.user.comment ?= 'Ranger User'
      ranger.user.home = "/var/lib/#{ranger.user.name}"
      ranger.user.gid = ranger.group.name
      ranger.usersync ?= {}
      ranger.usersync.conf_dir ?= '/etc/ranger/usersync/conf'
      ranger.usersync.log_dir ?= '/var/log/ranger'
      ranger.usersync.pid_dir ?= '/var/run/ranger'
      ranger.usersync.site ?= {}
      ranger.usersync.install ?= {}
      ranger.usersync.site ?= {}

Setup Scripts are used to install ranger-usersync tool. Setup scripts read properties 
from two files:
* First is `/usr/hdp/current/ranger-usersync/install.properties` file (documented).
* Second is `/usr/hdp/current/ranger-usersync/conf.dist/ranger-usersync-default.xml`.
Setup process creates files in `/etc/ranger/usersync/conf` dir and outputs final
 properties to `ranger-ugsync-site.xml` file.

## Policy Admin Tool

      ranger.usersync.install['POLICY_MGR_URL'] ?= ranger_admin_ctx.config.ryba.ranger.admin.install['policymgr_external_url']


## User Group Source Information
Specifies where the user/group information is extracted to be put into Ranger 
database:
 * Unix - get user information from /etc/passwd file and gets group information.
 from /etc/group file
 * LDAP - gets user information from LDAP service.
 In case LDAP is configured, Ryba looks first in the global `config.ryba.ranger['ldap_provider']` conf object 
 for needed properties (e.g. ldap url, bind dn...), and if not set try to discover
 it from `masson/core/openldap` module (if installed).

      ranger.usersync.install['SYNC_SOURCE'] ?= 'ldap'
      ranger.usersync.install['SYNC_INTERVAL'] ?= '1' # in minutes
      switch ranger.usersync.install['SYNC_SOURCE']
        when 'unix'
          ranger.usersync.install['MIN_UNIX_USER_ID_TO_SYNC'] ?= '300'
        when 'ldap'
          if  !ranger.usersync.install['SYNC_LDAP_URL']?
            [opldp_srv_ctx] = @contexts 'masson/core/openldap_server', require("#{__dirname}/../../node_modules/masson/core/openldap_server/configure").handler
            throw Error 'No openldap server configured' unless opldp_srv_ctx?
            {openldap_server} = opldp_srv_ctx.config
            ranger.usersync.install['SYNC_LDAP_URL'] ?= "#{openldap_server.uri}"
            ranger.usersync.install['SYNC_LDAP_BIND_DN'] ?= "#{openldap_server.root_dn}"
            ranger.usersync.install['SYNC_LDAP_BIND_PASSWORD'] ?= "#{openldap_server.root_password}"
            ranger.usersync.install['CRED_KEYSTORE_FILENAME'] ?= "#{ranger.usersync.conf_dir}/rangerusersync.jceks"
            ranger.usersync.install['SYNC_LDAP_USER_SEARCH_BASE'] ?= "ou=users,#{openldap_server.suffix}"
            ranger.usersync.install['SYNC_LDAP_USER_SEARCH_SCOPE'] ?= "ou=groups,#{openldap_server.suffix}"
            ranger.usersync.install['SYNC_LDAP_USER_OBJECT_CLASS'] ?= 'posixAccount'
            ranger.usersync.install['SYNC_LDAP_USER_SEARCH_FILTER'] ?= 'cn={0}'
            ranger.usersync.install['SYNC_LDAP_USER_NAME_ATTRIBUTE'] ?= 'cn'
            ranger.usersync.install['SYNC_GROUP_OBJECT_CLASS'] ?= 'posixGroup'
            ranger.usersync.install['SYNC_LDAP_USER_GROUP_NAME_ATTRIBUTE'] ?= 'cn'
            ranger.usersync.install['SYNC_LDAP_USERNAME_CASE_CONVERSION'] ?= 'none'
            ranger.usersync.install['SYNC_LDAP_GROUPNAME_CASE_CONVERSION'] ?= 'none'
            ranger.usersync.install['SYNC_GROUP_SEARCH_ENABLED'] ?= 'false'
            ranger.usersync.site['ranger.usersync.ldap.searchBase'] ?= "#{openldap_server.suffix}"
          ranger.usersync.install['MIN_UNIX_USER_ID_TO_SYNC'] ?= '500'
        else return throw new Error 'sync source is not legal'

## User Synchronization Process

      ranger.usersync.install['unix_user'] ?= ranger.user.name
      ranger.usersync.install['unix_group'] ?= ranger.group.name
      ranger.usersync.install['logdir'] ?= '/var/logs'

Nonetheless some of the properties are hard coded to `/usr/hdp/current/ranger-usersync/setup.py`
file. Administrators can override following properties.

      setup = ranger.usersync.setup ?= {}
      setup['pidFolderName'] ?= ranger.usersync.pid_dir
      setup['logFolderName'] ?= ranger.usersync.log_dir


SSl properties are not documented, they are extracted from setup.py scripts.

## SSL

      ranger.usersync.default ?= {}
      ranger.usersync.default['ranger.usersync.ssl'] ?= 'true'
      ranger.usersync.default['ranger.usersync.keystore.file'] ?= "#{ranger.usersync.conf_dir}/keystore"
      ranger.usersync.default['ranger.usersync.keystore.password'] ?= 'ranger123'
      ranger.usersync.default['ranger.usersync.truststore.file'] ?= "#{ranger.usersync.conf_dir}/truststore"
      ranger.usersync.default['ranger.usersync.truststore.password'] ?= 'ranger123'


## Env

      ranger.usersync.heap_size ?= '256m'
      ranger.usersync.opts ?= {}
      ranger.usersync.opts['javax.net.ssl.trustStore'] ?= '/etc/hadoop/conf/truststore'
      ranger.usersync.opts['javax.net.ssl.trustStorePassword'] ?= 'ryba123'    

## Dependencies 

    path = require 'path'

[ambari-conf-example]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.0/bk_Ranger_Install_Guide/content/ranger-usersync_settings.html)
[ranger-usersync]:(http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/install_and_start_user_sync_ranger.html)
