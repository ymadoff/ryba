
###
OpenLDAP ACL
============
###

module.exports = []
module.exports.push 'phyla/bootstrap'
module.exports.push 'phyla/core/openldap_server'

module.exports.push (ctx, next) ->
  require('./openldap_connection').configure ctx, next

###
After this call, the follwing command should succeed:

    ldapsearch -H ldap://hadoop1:389 -D cn=nssproxy,ou=users,dc=adaltas,dc=com -w test
###
module.exports.push name: 'OpenLDAP ACL # Permissions for nssproxy', callback: (ctx, next) ->
  {suffix} = ctx.config.openldap_server
  ctx.ldap_acl
    ldap: ctx.ldap_config
    name: 'olcDatabase={2}bdb,cn=config'
    acls: [
      to: 'attrs=userPassword,userPKCS12'
      by: [
        'dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage'
        "dn.exact=\"cn=nssproxy,ou=users,#{suffix}\" read"
        'self write'
        'anonymous auth'
        '* none'
      ]
    ,
      to: 'attrs=shadowLastChange'
      by: [
        'self write'
        'dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage'
        "dn.exact=\"cn=nssproxy,ou=users,#{suffix}\" read"
        '* none'
      ]
    ,
      to: "dn.subtree=\"#{suffix}\""
      by: [
        "dn.exact=\"cn=nssproxy,ou=users,#{suffix}\" read"
        '* none'
      ]
    ]
  , (err, modified) ->
    next err, if modified then ctx.OK else ctx.PASS




