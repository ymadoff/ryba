
# Elasticsearch (Docker) Prepare

Download Elasticsearch Plugins.

    module.exports =
      header: 'Elasticsearch Plugins'
      timeout: -1
      if: -> @contexts('ryba/esdocker')[0]?.config.host is @config.host
     ->
      clusters = @config.ryba.es_docker.clusters
      for es_name,es of clusters then do (es_name,es) =>
        @each es.plugins_urls, (plugins_options,plugins_callback) ->
          downloaded = false
          @each plugins_options.value, (plugin_options,callback) ->
            if !downloaded
              console.log "Trying do download #{plugins_options.key} using #{plugin_options.key}.."
              @file.cache
                ssh: null
                location: true
                fail: true
                header: "Accept: application/zip"
                source: plugin_options.key
                target: "/apps/Downloads/ryba/cache/#{plugins_options.key}.zip"
                ,(err,status) ->
                  if err
                    console.log "error: #{err}"
                  else
                    console.log "#{plugins_options.key} downloaded using #{plugin_options.key}.."
                    clusters["#{es_name}"].downloaded_urls["#{plugins_options.key}"]= plugin_options.key
                    downloaded=true
                  callback null
          @then (err) ->
            throw Error "failed to download #{plugins_options.key} out of all possible locations..." unless downloaded is true
            plugins_callback null
