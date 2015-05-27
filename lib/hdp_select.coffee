
###

Select the version of a package distributed by HDP.

Options include
*   `name` (string)
    Name of the package, required.
*   `version` (string)
    Version will be the latest auto-discovered version unless provided and can
    be a valid version, "latest" or "current".

###

module.exports = (ctx) ->
  return if ctx.registered 'hdp_select'
  ctx.register 'hdp_select', (options, callback) ->
    # options = name: options if typeof options is 'string'
    options.version ?= 'latest'
    if options.version and options.version not in ['latest', 'current']
      options.db['hdp_select.version.default'] = options.version
    ctx
    .call (_, callback) ->
      # Get the current or latest version
      ctx.execute
        cmd: """
        code=3
        if [ "#{options.version}" == "latest" ]; then
          version=`hdp-select versions | tail -1`
        elif [ "#{options.version}" == "current" ]; then
          version=`hdp-select status #{options.name} | sed 's/.* \\(.*\\)/\\1/'`*
          if [ "$version" == "None" ]; then
            version=`hdp-select versions | tail -1`
          fi
        else
          version='#{options.version}'
        fi
        if [ ! -d "/usr/hdp/$version" ]; then
          echo 'Failed to detect the latest HDP version'
          exit 1
        fi
        echo $version
        """
        not_if: options.db['hdp_select.version.default']
        shy: true
      , (err, executed, stdout, stderr) ->
        return callback err if err
        options.db['hdp_select.version.default'] = stdout.trim() if executed
        callback()
    .call (_, callback) ->
      version = options.db['hdp_select.version.default']
      # Set the service to its expected version
      ctx.execute
        cmd: """
        version=`hdp-select status #{options.name} | sed 's/.* \\(.*\\)/\\1/'`
        if [ $version == '#{version}' ]; then exit 3; fi
        hdp-select set #{options.name} #{version}
        """
        code_skipped: 3
      .then callback
    .then callback

each = require 'each'
wrap = require 'mecano/lib/misc/wrap'
string = require 'mecano/lib/misc/string'
