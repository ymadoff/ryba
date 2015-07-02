
## (hive server2, system)

This bug seems related to [HIVE-6866]

```
su -l hive -c 'ulimit -a'
# su: cannot set user id: Resource temporarily unavailable
```

[HIVE-6866]: https://issues.apache.org/jira/browse/HIVE-6866
