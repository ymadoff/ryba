# Ranger Admin Wait

Wait for Ranger Admin Policy Manager to start.

    module.exports = header: 'Rander Admin Wait', label_true: 'READY', handler: ->
      [ranger_admin_ctx] = (@contexts 'ryba/ranger/admin')
      {ranger} = ranger_admin_ctx.config.ryba
      protocol = if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true' then 'https' else 'http'
      port = ranger.admin.site["ranger.service.#{protocol}.port"]
      @wait_execute
        cmd: """
          curl --fail -H \"Content-Type: application/json\"  -k -X GET \ 
          -u admin:#{ranger.admin.password} \"#{ranger.admin.install['policymgr_external_url']}/service/users/1\"
        """
        code_skipped: [1,7,22]
