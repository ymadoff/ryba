# 
# # Ambari Server Wait
# 
#     module.exports = header: 'Ambari Standalone Wait', timeout: -1, handler: ->
#       [ambari_ctx] = @contexts 'ryba/ambari/standalone'
#       {ambari_standalone} = ambari_ctx.config.ryba
# 
# ## REST Access
# 
#       clusters_url = url.format
#         protocol: unless ambari_standalone.config['api.ssl'] is 'true'
#         then 'http'
#         else 'https'
#         hostname: options.fqdn
#         port: unless ambari_standalone.config['api.ssl'] is 'true'
#         then ambari_standalone.config['client.api.port']
#         else ambari_standalone.config['client.api.ssl.port']
#         pathname: '/api/v1/clusters'
#       oldcred = "admin:#{ambari_standalone.current_admin_password}"
#       newcred = "admin:#{ambari_standalone.admin_password}"
#       @wait.execute
#         header: 'REST'
#         cmd: """
#         curl -f -k -u #{newcred} #{clusters_url} || curl -f -k -u #{oldcred} #{clusters_url}
#         """
#         code_skipped: 7
# 
# ## Dependencies
# 
#     url = require 'url'
