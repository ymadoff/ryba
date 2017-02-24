
# HDP Install

    module.exports = 
      header: 'HDP Install'
      # if: -> @config.ryba.hdp_repo
      handler: (options) ->
        {proxy, hdp_repo} = @config.ryba
        @call
          header: 'Repository'
        , ->
          cache_file = hdp_repo.split('/').slice(-2).reverse().join('.')
          @file.download
            source: hdp_repo
            target: '/etc/yum.repos.d/hdp.repo'
            proxy: proxy
            cache_file: cache_file
          @system.execute
            cmd: "yum clean metadata; yum update -y"
            if: -> @status -1
          @call
            if: -> @status -2
            timeout: -1
          , (_, callback) ->
            options.log 'Upload PGP keys'
            @fs.readFile "/etc/yum.repos.d/hdp.repo", (err, content) =>
              return callback err if err
              keys = {}
              reg = /^pgkey=(.*)/gm
              while matches = reg.exec content
                keys[matches[1]] = true
              keys = Object.keys keys
              return callback null, true unless keys.length
              for key in keys
                @system.execute # TODO, should use `@file.download`
                  cmd: """
                  curl #{key} -o /etc/pki/rpm-gpg/#{path.basename key}
                  rpm --import  /etc/pki/rpm-gpg/#{path.basename key}
                  """
              @then callback
