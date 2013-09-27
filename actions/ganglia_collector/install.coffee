
fs = require 'fs'
eco = require 'eco'
each = require 'each'
mecano = require 'mecano'
misc = require 'mecano/lib/misc'

module.exports = [
  (ctx, next) ->
    @name 'Ganglia Collector: Package'
    @timeout 20000
    modified = false
    each(['rrdtool', 'ganglia', 'ganglia-gmetad'])
    .on 'item', (service, next) ->
      ctx.service
        name: service
      , (err, serviced) ->
        return next err if err
        modified = true if serviced
        next()
    .on 'both', (err) ->
      next err, if modified then ctx.OK else ctx.PASS
,
  (ctx, next) ->
    @name 'Ganglia Collector: Web'
    @timeout 20000
    each(['ganglia-web', 'httpd', 'php', 'apr', 'apr-util'])
    .on 'item', (service, next) ->
      ctx.service
        name: service
      , (err, serviced) ->
        return next err if err
        modified = true if serviced
        next()
    .on 'both', (err) ->
      return next err if err
      ctx.write
        match: /^Deny from all/mg
        replace: 'Allow from all'
        destination: '/etc/httpd/conf.d/ganglia.conf'
      , (err, replaced) ->
          return next err if err
          return next ctx.PASS unless replaced
          ctx.execute
            cmd: 'service httpd restart'
          , (err, executed) ->
              next err or ctx.OK
,
  (ctx, next) ->
    @name 'Ganglia Collector: Configuration'
    ctx.render
      source: "#{__dirname}/resources/gmetad.conf"
      destination: '/etc/ganglia/gmetad.conf'
      local_source: true
    , (err, rendered) ->
      next err, if rendered then ctx.OK else ctx.PASS
,
  (ctx, next) ->
    @name 'Ganglia Collector: Startup'
    @timeout 20000
    ctx.ssh.execute
      cmd: 'chkconfig gmetad on; service gmetad start'
    , (err, stream) ->
      stream.on 'exit', (code) ->
        next err, ctx.OK
]



# package "rrdtool" do
#   action :install
# end
# package "librrds-perl" do
#   action :install
# end
# package "librrd2-dev" do
#   action :install
# end

# # will also install gmetad
# package "ganglia-webfrontend" do
#   action :install
# end

# template "/etc/ganglia/gmetad.conf" do
#     owner "root"
#     group "root"
#     mode "0644"
#     source "ganglia/gmetad.conf"
# end

# service "apache2" do
#   supports :restart => true, :reload => true
#   action :enable
# end
# execute "Link Ganglia to Apache" do
#     command "ln -sf /etc/ganglia-webfrontend/apache.conf /etc/apache2/conf.d/ganglia.conf"
#     not_if "ls /etc/apache2/conf.d/ganglia.conf"
#     notifies :reload, resources(:service => "apache2")
# end
