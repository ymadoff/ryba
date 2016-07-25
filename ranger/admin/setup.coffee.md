
# Ranger Admin Setup

    module.exports =  header: 'Ranger Admin Setup', handler: ->
      {ranger} = @config.ryba

## Web UI Admin Account
Modify admin account password. By default the login:pwd  is `admin:admin`.

      @call header: 'Ranger Admin Account', handler:  ->
        @execute
          header: "Check admin password"
          cmd: """
            curl -H \"Content-Type: application/json\"  --fail -k -X GET \ 
            -u admin:#{ranger.admin.password} \"#{ranger.admin.install['policymgr_external_url']}/service/users/1\"
          """
          code_skipped: 22
          shy: true
        @execute
          unless: -> @status -1
          header: "Change admin password"
          cmd: """
            curl -H \"Content-Type: application/json\" --fail -k -X POST -d '#{JSON.stringify oldPassword:ranger.admin.current_password, updPassword:ranger.admin.password}'  \ 
            -u admin:#{ranger.admin.current_password} \"#{ranger.admin.install['policymgr_external_url']}/service/users/1/passwordchange\"
          """

## User Accounts
Deploying some user accounts. This middleware is here to serve
as an example of adding a user,and giving it some permission.
Requires `admin` user to have `ROLE_SYS_ADMIN`.

      @call header: 'Ranger X Users Accounts', handler: (_, callback) ->
        done = 0
        each ranger.xusers
        .call (xuser, _, next) =>
          @execute
            cmd: """
              curl --fail -H "Content-Type: application/json"   -k -X POST \ 
              -d '#{JSON.stringify xuser}' -u admin:#{ranger.admin.password} \
              \"#{ranger.admin.install['policymgr_external_url']}/service/xusers/secure/users\"
            """
            unless_exec: """
              curl --fail -H "Content-Type: application/json"   -k -X GET \ 
              -u #{xuser.name}:#{xuser.password} \
              \"#{ranger.admin.install['policymgr_external_url']}/service/users/profile\"
            """
          @call 
            if: -> @status -1
            handler: ->
              done++
          @then next
        .then (err) -> callback err, if done > 0 then true else false

## Dependencies

    each = require 'each'
