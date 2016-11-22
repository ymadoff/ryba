
# Hadoop KMS Configure

    module.exports = ->
      zoo_servers = @contexts 'ryba/zookeeper/server'
      {realm} = @config.ryba
      kms = @config.ryba.kms ?= {}

## layout

      kms.pid_dir ?= '/var/run/hadoop-kms'
      kms.conf_dir ?= '/etc/hadoop-kms/conf'
      kms.log_dir ?= '/var/log/hadoop-kms'

## User

      kms.user = name: kms.user if typeof kms.user is 'string'
      kms.user ?= {}
      kms.user.name ?= 'kms'
      kms.user.system ?= true
      kms.user.comment ?= 'Hadoop KMS User'
      kms.user.home ?= "/var/lib/#{kms.user.name}"
      kms.user.groups ?= ['hadoop']

## Group

      kms.group = name: kms.group if typeof kms.group is 'string'
      kms.group ?= {}
      kms.group.name ?= 'kms'
      kms.group.system ?= true
      kms.user.gid = kms.group.name

## Environment

      kms.http_port ?= 16000
      kms.admin_port ?= 16001
      kms.max_threads ?= 1000

## Configuration

      kms.site ?= {}
      kms.site['hadoop.kms.key.provider.uri'] ?= "jceks://file@/#{kms.conf_dir}/kms.keystore"
      kms.site['hadoop.security.keystore.java-keystore-provider.password-file'] ?= "#{kms.conf_dir}/kms.keystore.password"

## Cache

KMS caches keys for short period of time to avoid excessive hits to the
underlying key provider.

      kms.site['hadoop.kms.cache.enable'] ?= 'true'
      kms.site['hadoop.kms.cache.timeout.ms'] ?= '600000'

## Aggregated Audit logs

Audit logs are aggregated for API accesses to the GET_KEY_VERSION,
GET_CURRENT_KEY, DECRYPT_EEK, GENERATE_EEK operations.

Entries are grouped by the (user,key,operation) combined key for a configurable
aggregation interval after which the number of accesses to the specified
end-point by the user for a given key is flushed to the audit log.

The Aggregation interval is configured via the property :

      kms.site['hadoop.kms.current.key.cache.timeout.ms'] ?= '30000'

##  Delegation Token Configuration

KMS delegation token secret manager can be configured with the following properties:

      # How often the master key is rotated, in seconds. Default value 1 day.
      kms.site['hadoop.kms.authentication.delegation-token.update-interval.sec'] ?= '86400'
      # Maximum lifetime of a delagation token, in seconds. Default value 7 days.
      kms.site['hadoop.kms.authentication.delegation-token.max-lifetime.sec'] ?= '604800'
      # Renewal interval of a delagation token, in seconds. Default value 1 day.
      kms.site['hadoop.kms.authentication.delegation-token.renew-interval.sec'] ?= '86400'
      # Scan interval to remove expired delegation tokens.
      kms.site['hadoop.kms.authentication.delegation-token.removal-scan-interval.sec'] ?= '3600'

## HTTP Authentication Signature

      # zookeeper_quorum = for server in zoo_servers then "#{server.config.host}:#{server.config.ryba.zookeeper.port}"
      # kms.site['hadoop.kms.authentication.signer.secret.provider'] ?= 'zookeeper'
      # kms.site['hadoop.kms.authentication.signer.secret.provider.zookeeper.path'] ?= '/hadoop-kms/hadoop-auth-signature-secret'
      # kms.site['hadoop.kms.authentication.signer.secret.provider.zookeeper.connection.string'] ?= "#{zookeeper_quorum}"
      # kms.site['hadoop.kms.authentication.signer.secret.provider.zookeeper.auth.type'] ?= 'kerberos'
      # kms.site['hadoop.kms.authentication.signer.secret.provider.zookeeper.kerberos.keytab'] ?= "#{kms.conf_dir}/kms.keytab"
      # kms.site['hadoop.kms.authentication.signer.secret.provider.zookeeper.kerberos.principal'] ?= 'kms/#{@config.host}@{realm}'

## Access Control

KMS ACLs configuration are defined in the KMS /etc/hadoop-kms/kms-acls.xml
configuration file. This file is hot-reloaded when it changes.

KMS supports both fine grained access control as well as blacklist for kms
operations via a set ACL configuration properties.

A user accessing KMS is first checked for inclusion in the Access Control List
for the requested operation and then checked for exclusion in the Black list for
the operation before access is granted.

      kms.acls ?= {}
      kms.acls['hadoop.kms.acl.CREATE'] ?= '*'
      kms.acls['hadoop.kms.blacklist.CREATE'] ?= 'hdfs'
      kms.acls['hadoop.kms.acl.DELETE'] ?= '*'
      kms.acls['hadoop.kms.blacklist.DELETE'] ?= 'hdfs'
      kms.acls['hadoop.kms.acl.ROLLOVER'] ?= '*'
      kms.acls['hadoop.kms.blacklist.ROLLOVER'] ?= 'hdfs'
      kms.acls['hadoop.kms.acl.GET'] ?= '*'
      kms.acls['hadoop.kms.blacklist.GET'] ?= 'hdfs'
      kms.acls['hadoop.kms.acl.GET_KEYS'] ?= '*'
      kms.acls['hadoop.kms.blacklist.GET_KEYS'] ?= 'hdfs'
      kms.acls['hadoop.kms.acl.GET_METADATA'] ?= '*'
      kms.acls['hadoop.kms.blacklist.GET_METADATA'] ?= 'hdfs'
      kms.acls['hadoop.kms.acl.SET_KEY_MATERIAL'] ?= '*'
      kms.acls['hadoop.kms.blacklist.SET_KEY_MATERIAL'] ?= 'hdfs'
      kms.acls['hadoop.kms.acl.GENERATE_EEK'] ?= '*'
      kms.acls['hadoop.kms.blacklist.GENERATE_EEK'] ?= 'hdfs'
      kms.acls['hadoop.kms.acl.DECRYPT_EEK'] ?= '*'
      kms.acls['hadoop.kms.blacklist.DECRYPT_EEK'] ?= 'hdfs'
      kms.acls['hadoop.kms.acl.GET'] ?= '*'
      kms.acls['hadoop.kms.blacklist.GET'] ?= 'hdfs'
      kms.acls['hadoop.kms.acl.GET'] ?= '*'
      kms.acls['hadoop.kms.blacklist.GET'] ?= 'hdfs'
      kms.acls['hadoop.kms.acl.GET'] ?= '*'
      kms.acls['hadoop.kms.blacklist.GET'] ?= 'hdfs'
      kms.acls['hadoop.kms.acl.GET'] ?= '*'
      kms.acls['hadoop.kms.blacklist.GET'] ?= 'hdfs'

## Key Access Control

KMS supports access control for all non-read operations at the Key level. All
Key Access operations are classified as :

*   MANAGEMENT - createKey, deleteKey, rolloverNewVersion
*   GENERATE_EEK - generateEncryptedKey, warmUpEncryptedKeys
*   DECRYPT_EEK - decryptEncryptedKey
*   READ - getKeyVersion, getKeyVersions, getMetadata, getKeysMetadata, getCurrentKey
*   ALL - all of the above

These can be defined in the KMS etc/hadoop/kms-acls.xml as follows

For all keys for which a key access has not been explicitly configured, It is
possible to configure a default key access control for a subset of the operation
types.

It is also possible to configure a “whitelist” key ACL for a subset of the
operation types. The whitelist key ACL is a whitelist in addition to the
explicit or default per-key ACL. That is, if no per-key ACL is explicitly set,
a user will be granted access if they are present in the default per-key ACL or
the whitelist key ACL. If a per-key ACL is explicitly set, a user will be
granted access if they are present in the per-key ACL or the whitelist key ACL.

If no ACL is configured for a specific key AND no default ACL is configured AND
no root key ACL is configured for the requested operation, then access will be
DENIED.

NOTE: The default and whitelist key ACL does not support ALL operation qualifier.

      # ACL for create-key, deleteKey and rolloverNewVersion operations.
      # kms.acls['key.acl.testKey1.MANAGEMENT'] ?= '*'
      # ACL for generateEncryptedKey operations.
      # kms.acls['key.acl.testKey2.GENERATE_EEK'] ?= '*'
      # ACL for decryptEncryptedKey operations.
      # kms.acls['key.acl.testKey3.DECRYPT_EEK'] ?= 'admink3'
      # ACL for getKeyVersion, getKeyVersions, getMetadata, getKeysMetadata,
      # getCurrentKey operations
      # kms.acls['key.acl.testKey4.READ'] ?= '*'
      # ACL for ALL operations.
      # kms.acls['key.acl.testKey5.ALL'] ?= '*'
      # Whitelist ACL for MANAGEMENT operations for all keys.
      # kms.acls['whitelist.key.acl.MANAGEMENT'] ?= 'admin1'
