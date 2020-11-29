Reference:

```
$ ./create_userbucket.sh <instance> <user/bucket>
```

Example:

```
$ ./create_userbucket.sh s3 your-user-with-a-bucket
New user created: your-user-with-a-bucket
Generated password: feb9960b1f9b5b7774ec213ac75540d5
New bucket created: your-user-with-a-bucket
Created new policy: your-user-with-a-bucket-readwrite
Applied policy: your-user-with-a-bucket-readwrite to user your-user-with-a-bucket
```

In case your forgot your password, just delete the user, and rerun:
```
$ mc admin user remove s3 your-user-with-a-bucket
$ ./create_userbucket.sh s3 your-user-with-a-bucket
New user created: your-user-with-a-bucket
Generated password: e8907bf867bdb28708107b533860fcd3
Applied policy: your-user-with-a-bucket-readwrite to user your-user-with-a-bucket
```
