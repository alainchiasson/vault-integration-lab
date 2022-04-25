#!/usr/bin/env bash
#

echo "Login as user01"
# Login as User 1 - Note VAULT TOKEN gets stored in helper (~/.vault-token)
vault login -method=userpass username=user01 password=user01

#
echo "=== Show token info : user01"

# Check if user 1
vault token lookup 

echo "Store secrets in grp01 and grp02"
# Write secrets for grp01
vault kv put team-secrets/approle/grp01/test user=grp01 pwd=test00
vault kv put team-secrets/approle/grp02/test user=grp02 pwd=test00

echo "Read Back secrets as user01"
# Read secrets back
vault kv get team-secrets/approle/grp01/test
vault kv get team-secrets/approle/grp02/test

# Set up for login as AppRole

echo "Setup for login as grp01"
# Get ROLE ID
ROLE_ID=$(vault read -format=json auth/approle/role/grp01/role-id | jq -r '.data.role_id')

#Generate Secret ID
SECRET_ID=$(vault write -format=json -f auth/approle/role/grp01/secret-id | jq -r '.data.secret_id')

echo "=== Show token info : user01"
vault token lookup

echo "=== Login as grp01"
# Login - VAULT_TOKEN env overides (~/.vault-token)
export VAULT_TOKEN=$(vault write auth/approle/login -format=json role_id=${ROLE_ID} secret_id=${SECRET_ID} | jq -r '.auth.client_token')

echo "=== Show token info : grp01"
vault token lookup

echo "Read Back grp01 secrets"
# Test if it can be read.
vault kv get team-secrets/approle/grp01/test

echo "Error Reading grp02 secrets"
# Test if it can be read.
vault kv get team-secrets/approle/grp02/test

