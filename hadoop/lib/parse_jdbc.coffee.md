
# Parse JDBC URL

Enrich the result of `url.parse` with the "engine" and "db" properties.

    url = require 'url'

    module.exports = (jdbc) ->
      jdbc = jdbc.substr(5) if jdbc.substr(0, 5) is 'jdbc:'
      u = url.parse(jdbc)
      u.engine =  /(.*):/.exec(u.protocol)[1]
      u.db =  /\/(.*)/.exec(u.pathname)[1]
      u

