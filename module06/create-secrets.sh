#!/bin/bash

# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/secretsmanager/get-secret-value.html#examples
# Modify your maria.json

EXISTING=$(aws secretsmanager list-secrets --filters Key=name,Values=${21} --query 'SecretList[0].ARN' --output text)

if [ -z "$EXISTING" ] || [ "$EXISTING" = "None" ]; then
  echo "Creating AWS secret..."
  aws secretsmanager create-secret --name ${21} --secret-string file://maria.json
else
  echo "Secret '${21}' already exists, skipping creation."
fi

SECRET_ID=$(aws secretsmanager list-secrets --filters Key=name,Values=${21} --query 'SecretList[0].ARN' --output text)
USERVALUE=$(aws secretsmanager get-secret-value --secret-id $SECRET_ID --output=json | jq -r '.SecretString | fromjson | .user')
PASSVALUE=$(aws secretsmanager get-secret-value --secret-id $SECRET_ID --output=json | jq -r '.SecretString | fromjson | .pass')

echo $USERVALUE
echo $PASSVALUE
