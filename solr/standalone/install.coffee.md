
# Solr Install

    module.exports = header: 'Solr Install', handler: ->
      {solr, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]

## Users and Groups

      @group solr.group
      @user solr.user

## Packages

      @call header: 'Packages', timeout: -1, handler: ->
        @mkdir 
          destination: solr.install_dir
        @link 
          source: solr.install_dir
          destination: '/usr/solr/current'
        @download
          destination : '/var/tmp/ryba/solr.tar.gz'
          source: solr.source
        @extract
          source: '/var/tmp/ryba/solr.tar.gz'
          destination: solr.install_dir
          strip: 1
        @mkdir
          directory: solr.conf_dir
        @link 
          source: '/usr/solr/current/conf'
          destination: solr.conf_dir
## Layout

      # @call header: 'Solr Layout', timeout: -1, handler: ->
      #   @mkdir
      #     destination: solr.install_dir
      #   @mkdir
      #     destination: solr.var_dir
      #     uid: solr.user.name
      #     gid: solr.group.name
      #     mode: 0o0755
      #   @mkdir
      #     destination: solr.log_dir
      #     uid: solr.user.name
      #     gid: solr.group.name
      #     mode: 0o0755

## Kerberos

      # @krb5_addprinc
      #   header: 'Kerberos'
      #   principal: solr.principal
      #   randkey: true
      #   keytab: solr.keytab
      #   uid: solr.user.name
      #   gid: solr.group.name
      #   kadmin_principal: kadmin_principal
      #   kadmin_password: kadmin_password
      #   kadmin_server: admin_server

## Install

Solr archive comes with an install scripts which creates and sets directories, env vars & scripts.
Ryba execute this scripts then customize installation

      # @call header: 'Solr Packages', timeout: -1, handler: ->
      #   archive_name = path.basename solr.source
      #   archive_path = path.join solr.install_dir, archive_name
      #   @download
      #     source: solr.source
      #     destination: archive_path
      #   # Extracting is skipped if the script already exists and the download was skipped
      #   # We assume that the script is the same, and was already executed,
      #   #if not : forced is send by previous routine
      #   @execute
      #     cmd:"""
      #     tar xzf #{solr.install_dir}/solr-#{solr.version}.tgz solr-#{solr.version}/bin/install_solr_service.sh --strip-components=2
      #     """
      #     unless_exists: './install_solr_service.sh'
      #   @write
      #     destination: './install_solr_service.sh'
      #     match: /\nservice \$SOLR_SERVICE start(.*)(\n|.)*status\n/m
      #     replace: '\n'
      #   @execute
      #     cmd:"""
      #     rm -f /etc/init.d/solr
      #     ./install_solr_service.sh #{solr.install_dir}/solr-#{solr.version}.tgz -i #{solr.install_dir} -d #{solr.var_dir} -u #{solr.user.name} -p #{solr.port}
      #     kinit /#{solr.principal} -k -t #{solr.keytab}
      #     #{solr.install_dir}/solr/server/scripts/cloud-scripts/zkcli.sh -zkhost "#{solr.zkhosts}" -cmd bootstrap -solrhome #{solr.user.home}
      #     """
      #     if: -> @status -1
      
      # @call header: 'Environment', timeout: -1, handler: ->
      #   write = [
      #     match: /^SOLR_PID_DIR=.*/m
      #     replace: "SOLR_PID_DIR=#{solr.var_dir} # RYBA CONF `solr.var_dir`, DON'T OVERWRITE"
      #   ,
      #     match: /^SOLR_HOME=.*/m
      #     replace: "SOLR_HOME=#{solr.user.home} # RYBA CONF `solr.user.home`, DON'T OVERWRITE"
      #   ,
      #     match: /^LOG4J_PROPS=.*/m
      #     replace: "LOG4J_PROPS=#{path.join solr.var_dir, 'log4j.properties'} # RYBA CONF `solr.var_dir`/log4j.properties, DON'T OVERWRITE"
      #   ,
      #     match: /^SOLR_LOGS_DIR=.*/m
      #     replace: "SOLR_LOGS_DIR=#{solr.log_dir} # RYBA CONF `solr.log_dir`, DON'T OVERWRITE"
      #   ,
      #     match: /^SOLR_PORT=.*/m
      #     replace: "SOLR_PORT=#{solr.port} # RYBA CONF `solr.port`, DON'T OVERWRITE"
      #   ]
      #   if solr.mode is 'cloud'
      #     write.unshift
      #       match: /^SOLR_MODE=.*/m
      #       replace: "SOLR_MODE=solrcloud # RYBA CONF, DON'T OVERWRITE"
      #       before: /^(.*)ZK_HOST=.*/m
      #     write.unshift
      #       match: /^(.*)ZK_HOST=.*/m
      #       replace: "ZK_HOST=#{solr.zkhosts} # RYBA CONF, DON'T OVERWRITE"
      #   @write
      #     destination: path.join solr.var_dir, 'solr.in.sh'
      #     write: write

## Config Set
      # 
      # @mkdir
      #   header: 'Config Set Pool'
      #   destination: path.join solr.user.home, 'configsets'
      #   uid: solr.user.name
      #   gid: solr.group.name
      #   mode: 0o0755

# ## Titan
#
# ### Titan Config Set
#
#     module.exports.push header: 'Solr # Titan Config Set', handler: ->
#       titan_ctxs = @contexts 'ryba/titan', require('../titan').configure
#       return next() if titan_ctxs.length is 0
#       {solr} = @config.ryba
#       modified = false
#       titan_set = path.join solr.user.home, 'configsets', 'titan'
#       conf_sample = path.join solr.install_dir, 'solr/server/solr/configsets/data_driven_schema_configs/conf/'
#       do_mkdir = () ->
#         @copy
#           destination: titan_set
#           source: conf_sample
#           uid: solr.user.name
#           gid: solr.group.name
#           unless_exists: titan_set
#           mode: 0o0755
#         , (err, changed) ->
#           return next err if err
#           modified ||= changed
#           do_write()
#       do_write = () ->
#         @write [
#           destination: path.join titan_set, 'solrconfig.xml'
#           source: "#{__dirname}/../resources/solr/solrconfig.xml"
#           local_source: true
#           mode: 0o0644
#           backup: true
#           uid: solr.user.name
#           gid: solr.user.name
#         ,
#           destination: path.join titan_set, 'schema.xml'
#           source: "#{__dirname}/../resources/titan/solr_schema.xml"
#           local_source: true
#           mode: 0o0644
#           backup: true
#           uid: solr.user.name
#           gid: solr.user.name
#         ], (err, written) ->
#           return next err if err
#           return if modified then do_create()
#           else next null, modified
#       do_create = () ->
#         #@exec
#         #  cmd: "#{solr.install_dir}/solr/bin/solr create_collection -c titan -d #{solr.user.home}/configsets/titan"
#         #, (err, executed, stdout, stderr) ->
#         #  ## TODO
#         return next null, 'UNFINISHED'
#       do_mkdir()
#
# ### Solr Collection
#
#     module.exports.push header: 'Solr # Titan Collection', handler: ->
#       return next() unless @config.ryba.titan.config['index.search.backend'] is 'solr'
#       next()
#
      # @call header: 'Solr Tuning', handler: ->
      #   return
      #next null, 'TODO'

## Dependencies

    path = require 'path'
