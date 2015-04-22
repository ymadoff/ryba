
###
Options include
*   ssh
*   mode
*   content
*   kerberos [boolean]

A server configuration is expected to define a keytab. Add the principal
name if the keytab store multiple tickets. A client configuration for an
application will be similar and also defines a keytab. A client configuration
for a login user will usually get the ticket from the user ticket cache created
with a `kinit` command.

Example:

```
ctx.repoinfo
  stack: '2.2'
  repoid: 'HDP-2.2'
  baseurl: 'http://...'
, (err, modified) ->
  console.log err
```

###


module.exports = (ctx) ->
  ctx.repoinfo = (options, callback) ->
    # Quick fix
    # waiting for context registration of mecano actions as well as
    # waiting for uid_gid moved from wrap to their expected location
    options.ssh ?= ctx.ssh
    options.mode ?= 0o600
    options.backup ?= true
    wrap null, arguments, (options, callback) ->
      destination = "/var/lib/ambari-server/resources/stacks/HDP/#{options.stack}/repos/repoinfo.xml"
      parser = new xml2js.Parser()
      ctx.fs.readFile destination, (err, data) ->
        return callback err if err
        parser.parseString data, (err, data) ->
          return callback err if err
          for repo, repoinfo of data.reposinfo
            console.dir repo, repoinfo
          console.log 'Done.'

      # writes = []
      # for version of local
      #   markup = builder.create 'reposinfo', version: '1.0', encoding: 'UTF-8'
      #   for platforms, config of local[version]
      #     for platform in platforms.split ','
      #       os = markup.ele 'os', type: platform
      #       for conf in config
      #         repo = os.ele 'repo'
      #         for k, v of conf
      #           repo.ele k, null, v
      #   writes.push
      #     content: markup.end pretty: true
      #     destination: "/var/lib/ambari-server/resources/stacks/HDP/#{version}/repos/repoinfo.xml"
      # ctx.write writes, next
      # ctx.write options, callback

xml2js = require 'xml2js'
wrap = require 'mecano/lib/misc/wrap'
