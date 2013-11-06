
###
OpenLDAP ACL
============
###

module.exports = []

openldap_connection = require './openldap_connection'
module.exports.push openldap_connection.configure

###
After this call, the follwing command should succeed:

    ldapsearch -H ldap://hadoop1:389 -D cn=nssproxy,ou=users,dc=adaltas,dc=com -w test
###
module.exports.push (ctx, next) ->
  @name 'OpenLDAP ACL # User permissions for nssproxy'
  ctx.ldap_acl [
    ldap: ctx.ldap_config
    name: 'olcDatabase={2}bdb,cn=config'
    to: 'attrs=userPassword,userPKCS12'
    by: [
      'dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage'
      'dn.exact="cn=nssproxy,ou=users,dc=adaltas,dc=com" read'
      'self write'
      'anonymous auth'
      '* none'
    ]
  ,
    ldap: ctx.ldap_config
    name: 'olcDatabase={2}bdb,cn=config'
    to: 'attrs=shadowLastChange'
    by: [
      'self write'
      'dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage'
      'dn.exact="cn=nssproxy,ou=users,dc=adaltas,dc=com" read'
      '* none'
    ]
  ,
    ldap: ctx.ldap_config
    name: 'olcDatabase={2}bdb,cn=config'
    to: 'dn.subtree="dc=adaltas,dc=com"'
    by: [
      'dn.exact="cn=nssproxy,ou=users,dc=adaltas,dc=com" read'
      '* none'
    ]
  ], (err, modified) ->
    next err, if modified then ctx.OK else ctx.PASS




