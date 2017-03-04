
## Configuration

Pig uses the "hdfs" configuration. It also declare 2 optional properties:

*   `hdp.force_check` (string)
    Force the execution of the check action on each run, otherwise it will
    run only on the first install. The property is shared by multiple
    modules and default to false.
*   `pig.user` (object|string)
    The Unix Pig login name or a user object (see Nikita User documentation).
*   `hdp.pig.conf_dir` (string)
    The Pig configuration directory, dont overwrite, default to "/etc/pig/conf".

Example:

```json
{
  "ryba": {
    "pig": {
      "config": {
        "pig.cachedbag.memusage": "0.1",
        "pig.skewedjoin.reduce.memusage", "0.3"
      }
    },
    force_check: true
  }
}
```

    module.exports = ->
      pig = @config.ryba.pig ?= {}
      # Layout
      pig.conf_dir ?= '/etc/pig/conf'
      # Configuration
      pig.config ?= {}
