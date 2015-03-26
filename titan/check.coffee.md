
# Titan Check

    module.exports = []

## Check Configuration

Check the configuration file (current.properties)

    module.exports.push name: 'Titan # Check Configuration', timeout: -1, label_true: 'CHECKED', handler: (ctx, next) ->
      next null, 'TODO'