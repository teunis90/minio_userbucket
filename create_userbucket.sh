#!/bin/bash

instance=${1}
new_user=${2}
random_password=$(date | md5sum | awk '{print $1}')
mc_installed=$(command -v mc)


if [ $? -ne 0 ]; then
  echo "mc command not installed, exiting .."
  exit 1
fi

if [ $# -ne 2 ]; then
  echo "No user or s3-instance supplied, exiting .."
  exit 1
fi

user_exists=$(mc admin user info ${instance} ${new_user} --json | jq -r .status)
if [ ${user_exists} == "error" ]; then
  # user does not exist, create it
  new_user_result=$(mc admin user add ${instance} ${new_user} ${random_password} --json | jq -r .status)
  if [ ${new_user_result} == "error" ]; then
    echo "User creation failed, exiting .."
    exit 1
  else
    user_created=1
  fi
else
  user_created=0
fi

bucket_exists=$(mc stat ${instance}/${new_user} --json | jq -r .status)
if [ ${bucket_exists} == "error" ]; then
  new_bucket_result=$(mc mb ${instance}/${new_user} --json | jq -r .status)
  if [ ${new_bucket_result} == "error" ]; then
    echo "User creation failed, exiting .."
    exit 1
  else
    bucket_created=1
  fi
else
  bucket_created=0 
fi

if [ "${user_created}" == "1" ]; then
  echo "New user created: ${new_user}"
  echo "Generated password: ${random_password}"
fi
if [ "${bucket_created}" == "1" ]; then
  echo "New bucket created: ${new_user}"
fi

cat << EOF > /tmp/minio_s3_policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "*"
        ]
      },
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListAllMyBuckets"
      ],
      "Resource": [
        "arn:aws:s3:::${new_user}/"
      ]
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "*"
        ]
      },
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::${new_user}",
        "arn:aws:s3:::${new_user}/*"
      ]
    }
  ]
}
EOF

policy_exist=$(mc admin policy list ${instance} --json | jq -r .policy | grep ${new_user}-readwrite)
if [ "$?" == "1" ]; then
  policy_add=$(mc admin policy add ${instance} ${new_user}-readwrite /tmp/minio_s3_policy.json --json | jq -r .status)
  if [ ${new_bucket_result} == "error" ]; then
    echo "Policy creation failed, exiting .."
    exit 1
  fi
  echo "Created new policy: ${new_user}-readwrite"
fi

user_current_policy=$(mc admin user info ${instance} ${new_user} --json | jq -r .policyName)
if [ "${user_current_policy}" != "${new_user}-readwrite" ]; then
  policy_set=$(mc admin policy set ${instance} ${new_user}-readwrite user=${new_user} --json | jq -r .status)
  if [ ${policy_set} == "error" ]; then
    echo "Setting policy failed, exiting .."
    exit 1
  fi
  echo "Applied policy: ${new_user}-readwrite to user ${new_user}"
fi