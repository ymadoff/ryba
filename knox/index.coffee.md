
# Knox

The Apache Knox Gateway is a REST API gateway for interacting with Apache Hadoop
clusters. The gateway provides a single access point for all REST interactions
with Hadoop clusters.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'

## Configure

    module.exports.configure = (ctx) ->
      knox = ctx.config.ryba.knox ?= {}
      knox.conf_dir ?= '/etc/knox/conf'
      # User
      knox.user = name: knox.user if typeof knox.user is 'string'
      knox.user ?= {}
      knox.user.name ?= 'knox'
      knox.user.system ?= true
      knox.user.comment ?= 'Knox Gateway User'
      knox.user.home ?= '/var/lib/knox'
      # Group
      knox.group = name: knox.group if typeof knox.group is 'string'
      knox.group ?= {}
      knox.group.name ?= 'knox'
      knox.group.system ?= true
      knox.user.gid = knox.group.name
      # Kerberos
      knox.krb5_user ?= {}
      knox.krb5_user.principal ?= "#{knox.user.name}/#{ctx.config.host}@#{ctx.config.ryba.realm}"
      knox.krb5_user.keytab ?= '/etc/security/keytabs/knox.service.keytab'
      # Env
      knox.env ?= {}
      knox.env.app_mem_opts ?= '-Xmx8192m'
      # Configuration
      knox.site ?= {}
      knox.site['gateway.port'] ?= '8443'
      knox.site['gateway.path'] ?= 'gateway'
      knox.site['java.security.krb5.conf'] ?= '/etc/krb5.conf'
      knox.site['java.security.auth.login.config'] ?= "#{knox.conf_dir}/knox.jaas"
      knox.site['gateway.hadoop.kerberos.secured'] ?= 'true'
      knox.site['sun.security.krb5.debug'] ?= 'true'
      knox.topologies ?= {}
      # Knox SSL
      throw Error 'Required property "ryba.ssl.cacert" or "ryba.knox.ssl.cacert"' unless ctx.config.ryba.ssl?.cacert? or knox.ssl.cacert?
      throw Error 'Required property "ryba.ssl.cert"' unless ctx.config.ryba.ssl?.cert? or knox.ssl.cert?
      throw Error 'Required property "ryba.ssl.key"' unless ctx.config.ryba.ssl?.key? or knox.ssl.key?
      throw Error 'Required property "dsp.clients.cafile"' unless ctx.config.dsp.clients?.cafile? or knox.ssl.cafile?
      throw Error 'Required property "dsp.clients.caname"' unless ctx.config.dsp.clients?.caname? or knox.ssl.caname?
      knox.ssl ?= {}
      knox.ssl.storepass ?= 'knox_master_secret_123'
      knox.ssl.cacert ?= ctx.config.ryba.ssl.cacert
      knox.ssl.cert ?= ctx.config.ryba.ssl.cert
      knox.ssl.key ?= ctx.config.ryba.ssl.key
      knox.ssl.cafile ?= ctx.config.dsp.clients.cafile
      knox.ssl.caname ?= ctx.config.dsp.clients.caname

## Configuration for Proxy Users

      knox_hosts = ctx.contexts('ryba/knox').map((ctx) -> ctx.config.host).join ','
      hadoop_ctxs = ctx.contexts ['ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm']
      for hadoop_ctx in hadoop_ctxs
        hadoop_ctx.config.ryba ?= {}
        hadoop_ctx.config.ryba.core_site ?= {}
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{knox.user.name}.hosts"] ?= knox_hosts
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{knox.user.name}.groups"] ?= '*'
      httpfs_ctxs = ctx.contexts 'ryba/hadoop/httpfs'
      for httpfs_ctx in httpfs_ctxs
        httpfs_ctx.config.ryba ?= {}
        httpfs_ctx.config.ryba.httpfs ?= {}
        httpfs_ctx.config.ryba.httpfs.site ?= {}
        httpfs_ctx.config.ryba.httpfs.site["httpfs.proxyuser.#{knox.user.name}.hosts"] ?= knox_hosts
        httpfs_ctx.config.ryba.httpfs.site["httpfs.proxyuser.#{knox.user.name}.groups"] ?= '*'
      oozie_ctxs = ctx.contexts 'ryba/oozie/server'
      for oozie_ctx in oozie_ctxs
        oozie_ctx.config.ryba ?= {}
        oozie_ctx.config.ryba.oozie ?= {}
        oozie_ctx.config.ryba.oozie.site ?= {}
        oozie_ctx.config.ryba.oozie.site["oozie.service.ProxyUserService.proxyuser.#{knox.user.name}.hosts"] ?= knox_hosts
        oozie_ctx.config.ryba.oozie.site["oozie.service.ProxyUserService.proxyuser.#{knox.user.name}.groups"] ?= '*'

## Configure topology

LDAP authentication is configured by adding a "ShiroProvider" authentication 
provider to the cluster's topology file. When enabled, the Knox Gateway uses 
Apache Shiro (org.apache.shiro.realm.ldap.JndiLdapRealm) to authenticate users 
against the configured LDAP store.
      
      for nameservice,topology of knox.topologies
        topology ?= {}
        # Configure providers
        topology.providers ?= {}

        ldap = topology.providers['authentication'] ?= {}
        ldap.name ?= 'ShiroProvider'
        ldap.config ?= {}
        ldap.config['sessionTimeout'] ?= 30
        realms = ['ldapRealm']
        realm_config = {}
        realm_config['ldapRealm'] = topology
      
        if topology.group?
          throw Error 'Required property lookup' unless topology.group.lookup?
          realms.push 'ldapGroupRealm'
          realm_config['ldapGroupRealm'] = ctx.config.sssd.config[topology.group.lookup]

        

        for realm in realms

          ldap.config["main.#{realm}"] ?= 'org.apache.hadoop.gateway.shirorealm.KnoxLdapRealm' # OpenLDAP implementation
          # ldap.config['main.ldapRealm'] ?= 'org.apache.shiro.realm.ldap.JndiLdapRealm' # AD implementation
          ldap.config["main.#{realm}".replace('Realm','')+"ContextFactory"] ?= 'org.apache.hadoop.gateway.shirorealm.KnoxLdapContextFactory'
          ldap.config["main.#{realm}.contextFactory"] ?= '$'+"#{realm}".replace('Realm','')+'ContextFactory'
        # ctxs = ctx.contexts 'masson/core/openldap_server'
        
          throw Error 'Required property ldap_uri' unless realm_config[realm]['ldap_uri']?
          throw Error 'Required property ldap_default_bind_dn' unless realm_config[realm]['ldap_default_bind_dn']?
          throw Error 'Required property ldap_default_authtok' unless realm_config[realm]['ldap_default_authtok']?
          throw Error 'Required property ldap_search_base' unless realm_config[realm]['ldap_search_base']?
          if realm == 'ldapGroupRealm' then throw Error 'Required property ldap_search_base' unless realm_config[realm]['ldap_group_search_base']?

          ldap.config["main.#{realm}.userDnTemplate"] = realm_config[realm]['userDnTemplate'] if realm_config[realm]['userDnTemplate']?
          ldap.config["main.#{realm}.contextFactory.url"] = realm_config[realm]['ldap_uri'].split(',')[0]
          ldap.config["main.#{realm}.contextFactory.systemUsername"] = realm_config[realm]['ldap_default_bind_dn']
          ldap.config["main.#{realm}.contextFactory.systemPassword"] = realm_config[realm]['ldap_default_authtok']
          ldap.config["main.#{realm}.searchBase"] = if realm == 'ldapGroupRealm' then realm_config[realm]['ldap_group_search_base'] else realm_config[realm]['ldap_search_base']


          ldap.config["main.#{realm}.contextFactory.authenticationMechanism"] ?= 'simple'
          ldap.config["main.#{realm}.authorizationEnabled"] ?= 'true'
      
      # we redo the test here, so that this params are rendered at the end of the authentication provider section 
        if topology.group?
          ldap.config['main.ldapGroupRealm.groupObjectClass'] = realm_config["ldapRealm"].group.groupObjectClass ?= "posixGroup"
          ldap.config['main.ldapGroupRealm.memberAttribute'] = realm_config["ldapRealm"].group.memberAttribute ?= "memberUid"
          ldap.config['main.ldapGroupRealm.memberAttributeValueTemplate'] = 'uid={0},' + realm_config["ldapRealm"]['ldap_search_base']

        ldap.config['urls./**'] ?= 'authcBasic'
        ldap.config['main.securityManager.realms'] = ["$"+realm for realm in realms].join "," if topology.group?

The Knox Gateway identity-assertion provider maps an authenticated user to an 
internal cluster user and/or group. This allows the Knox Gateway accept requests
from external users without requiring internal cluster user names to be exposed. 
        
        topology.providers['identity-assertion'] ?= name: 'Pseudo'
        topology.providers['authorization'] ?= name: 'AclsAuthz'
        ## Services
        topology.services ?= {}
        topology.services.knox ?= ''
        # Namenode & WebHDFS
        nn_ctxs = ctx.contexts 'ryba/hadoop/hdfs_nn', require('../hadoop/hdfs_nn').configure
        fs_ctxs = ctx.contexts 'ryba/hadoop/httpfs', require('../hadoop/httpfs').configure
        if nn_ctxs.length  
          # Namenode
          topology.services['namenode'] ?= nn_ctxs[0].config.ryba.core_site['fs.defaultFS']
          if fs_ctxs.length
            if fs_ctxs.length > 1
              topology.providers['ha'] ?= name: 'HaProvider'
              topology.providers['ha'].config ?= {}
              topology.providers['ha'].config['WEBHDFS'] ?= 'maxFailoverAttempts=3;failoverSleep=1000;maxRetryAttempts=300;retrySleep=1000;enabled=true'
            topology.services['webhdfs'] ?= fs_ctxs.map (ctx) -> "http#{if ctx.config.ryba.httpfs.env.HTTPFS_SSL_ENABLED is 'true' then 's' else ''}://#{ctx.config.host}:#{ctx.config.ryba.httpfs.http_port}/webhdfs/v1"
          else if nn_ctxs.length > 1
            topology.providers['ha'] ?= name: 'HaProvider'
            topology.providers['ha'].config ?= {}
            topology.providers['ha'].config['WEBHDFS'] ?= 'maxFailoverAttempts=3;failoverSleep=1000;maxRetryAttempts=300;retrySleep=1000;enabled=true'
            topology.services['webhdfs'] ?= []
            for nn_ctx in ctxs
              protocol = if nn_ctx.config.ryba.hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
              host = nn_ctx.config.host
              shortname = nn_ctx.config.shortname
              port = nn_ctx.config.ryba.hdfs.site["dfs.namenode.#{protocol}-address.#{nn_ctx.config.ryba.nameservice}.#{shortname}"].split(':')[1]
              action = if host is nn_ctx.config.ryba.active_nn_host then 'unshift' else 'push'
              topology.services['webhdfs'][action] "#{protocol}://#{host}:#{port}/webhdfs/v1"
          else
            protocol = if ctxs[0].config.ryba.hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
            host = ctxs[0].config.host
            port = ctxs[0].config.ryba.hdfs.site["dfs.namenode.#{protocol}-address"].split(':')[1]
            topology.services['webhdfs'] ?= "#{protocol}://#{host}:#{port}/webhdfs/v1"
        # Jobtracker
        ctxs = ctx.contexts 'ryba/hadoop/yarn_rm', require('../hadoop/yarn_rm').configure
        if ctxs.length
          rm_shortname = if ctxs.length > 1 then ".#{ctxs[0].config.shortname}" else ''    
          rm_address = ctxs[0].config.ryba.yarn.site["yarn.resourcemanager.address#{rm_shortname}"]
          topology.services['jobtracker'] ?= "rpc://#{rm_address}" if rm_address?
        # Hive
        ctxs = ctx.contexts 'ryba/hive/server2', require('../hive/server2').configure
        if ctxs.length
          host = ctxs[0].config.host
          port = ctxs[0].config.ryba.hive.site['hive.server2.thrift.http.port']
          topology.services['hive'] ?= "http://#{host}:#{port}/cliservice"
        # Hive WebHCat
        ctxs = ctx.contexts 'ryba/hive/webhcat', require('../hive/webhcat').configure
        if ctxs.length
          host = ctxs[0].config.host
          port = ctxs[0].config.ryba.webhcat.site['templeton.port']
          topology.services['webhcat'] ?= "http://#{host}:#{port}/templeton"
        # Oozie
        ctxs = ctx.contexts 'ryba/oozie/server', require('../oozie/server').configure
        if ctxs.length
          topology.services['oozie'] ?= ctxs[0].config.ryba.oozie.site['oozie.base.url']
        # WebHBase
        ctxs = ctx.contexts 'ryba/hbase/rest', require('../hbase/rest').configure
        if ctxs.length
          protocol = if ctxs[0].config.ryba.hbase.site['hbase.rest.ssl.enabled'] is 'true' then 'https' else 'http'
          host = ctxs[0].config.host
          port = ctxs[0].config.ryba.hbase.site['hbase.rest.port']
          topology.services['webhbase'] ?= "#{protocol}://#{host}:#{port}"
  
    module.exports.push commands: 'check', modules: 'ryba/knox/check'

    module.exports.push commands: 'install', modules: [
      'ryba/knox/install'
      'ryba/knox/start'
      'ryba/knox/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/knox/start'

    module.exports.push commands: 'stop', modules: 'ryba/knox/stop'

    module.exports.push commands: 'status', modules: 'ryba/knox/status'

## Dependencies

    path = require 'path'

# Knox Installation and configuration

## Configure LDAP

There is two ways to configure Knox for LDAP authorization.
Final user give a MD5 digest login:password to Knox. Knox checks this user in 
an LDAP.
There is two different case
1. the digest is sufficient to contact LDAP
2. LDAP is readable through a specific user

### LDAP is readable by any user

To check if LDAP is readable by any user please execute on Knox client
```bash
ldapsearch -h $ldap_host -p $ldap_port -D "$user_dn" -w password -b "$user_dn" "objectclass=*"
```

If the result is OK then in knox topology shiro provider please set
main.ldapRealm.userDnTemplate.

This value is used to construct user_dn with the user provided by the MD5-digest.

for example :

if main.ldapRealm.userDnTemplate = cn={0},ou=users,dc=ryba then this request:

```
curl -iku hdfs:test123 https://$knox_host:$knox_port/gateway/$cluster/$service
```
will result in this equivalent ldap check (it is not what Knox exactly do, but is equivalent)

```
ldapsearch -h $ldap_host -p $ldap_port -D "cn=hdfs,ou=users,dc=ryba" -w test123 -b "cn=hdfs,ou=users,dc=ryba" "objectclass=*"
```

### LDAP search

If LDAP is not readable, or user_dn cannot be assessed with username 
(users are located in more than one branch in the LDAP tree),
you need to use the knox ldap search functionality

Please specify:
```xml
<param>
    <name>main.ldapRealm.userObjectClass</name>
    <value>person</value>
</param>
<param>
    <!-- filter from this base -->
    <name>main.ldapRealm.searchBase</name>
    <value>ou=users,dc=ryba</value>
</param>
<param>
    <!-- filter: uid={0} -->
    <name>ldapRealm.userSearchAttributeName</name>
    <value>uid</value>
</param>
<param>
    <!-- granted ldap user if needed -->
    <name>main.ldapRealm.contextFactory.systemUsername</name>
    <value>cn=Manager,dc=ryba</value>
</param>
<param>
    <name>main.ldapRealm.contextFactory.systemPassword</name>
    <value>test</value>
</param>
```

which is equivalent to 
```bash
ldapsearch -h $ldap_host -p $ldap_port -D "$systemUsername" -w $systemPassword -b "$searchBase" -Z "$attr={0}" "objectclass=$userObjectClass"
```

## HDFS HA

Hortonworks documentation is uncorrect (last checked documentation: hdp-2.3.2).
Hence please refer to the [official Apache documentation][doc]

[doc]: http://knox.apache.org/books/knox-0-6-0/user-guide.html
