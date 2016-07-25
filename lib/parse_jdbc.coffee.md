
# Parse JDBC URL

Enrich the result of `url.parse` with the "engine" and "db" properties.

Exemple:

```
parse 'jdbc:mysql://host1:3306,host2:3306/hive?createDatabaseIfNotExist=true'
{ engine: 'mysql',
  addresses: 
   [ { host: 'host1', port: '3306' },
     { host: 'host2', port: '3306' } ],
  db: 'hive' }
```

    module.exports = (jdbc) ->
      if /^jdbc:mysql:/.test jdbc
        [_, engine, addresses, db] = /^jdbc:(.*?):\/+(.*?)\/(.*?)(\?(.*)|$)/.exec jdbc
        addresses = addresses.split(',').map (address) ->
          [host, port] = address.split ':'
          host: host, port: port
        engine: 'mysql'
        addresses: addresses
        db: db
      else if /^jdbc:postgresql:/.test jdbc
        [_, engine, addresses, db] = /^jdbc:(.*?):\/+(.*?)\/(.*?)(\?(.*)|$)/.exec jdbc
        addresses = addresses.split(',').map (address) ->
          [host, port] = address.split ':'
          host: host, port: port
        engine: 'postgresql'
        addresses: addresses
        db: db
      else
        throw Error 'Invalid JDBC URL'
