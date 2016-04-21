
# Commons Configure

    module.exports = handler: ->
      nifi = @config.ryba.nifi ?= {}
      nifi.version ?= '0.6.0'
      nifi.source ?= "https://archive.apache.org/dist/nifi/#{nifi.version}/nifi-#{nifi.version}-bin.tar.gz"
      nifi.root_dir ?= '/opt'

## User and Groups

      # User
      nifi.user = name: nifi.user if typeof nifi.user is 'string'
      nifi.user ?= {}
      nifi.user.name ?= 'nifi'
      nifi.user.system ?= true
      nifi.user.comment ?= 'NiFi User'
      nifi.user.home ?= '/var/lib/nifi'
      # Group
      nifi.group = name: nifi.group if typeof nifi.group is 'string'
      nifi.group ?= {}
      nifi.group.name ?= 'nifi'
      nifi.group.system ?= true
      nifi.user.limits ?= {}
      nifi.user.limits.nofile ?= 64000
      nifi.user.limits.nproc ?= true
      nifi.user.gid = nifi.group.name 
