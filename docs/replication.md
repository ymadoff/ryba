
# Replication

Ryba can be configured in distributed mode. Distribution is defined just as the
same way as in GIT.

There is no dependency on an external storage such as a database. Configuration,
source code and others are all stored on disk. For this reason, we recommand
using git (or any other version control tool) to synchronize your data.

The excellent [git-annex] allows managing files with git, without checking the
file contents into git. [git-annex] is designed for git users who love the
command line. For everyone else, the [git-annex assistant] turns git-annex into
an easy to use folder synchroniser.

[git-annex assistant]: http://git-annex.branchable.com/assistant/
[git-annex]: http://git-annex.branchable.com/
