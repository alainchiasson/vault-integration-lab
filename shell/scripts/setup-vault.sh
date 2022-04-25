#!/usr/bin/env bash
#

# Using a preset Vault Root Token 
vault login root

# Add team-secrets kv2
vault secrets enable -path=team-secrets kv-v2

# Enable vault user-pass 
vault auth enable userpass


# Add User Policies
vault policy write mng_team_secrets - <<EOF
path "team-secrets/data/" {
    capabilities = ["list", "read", "create", "update", "delete"]
}
path "team-secrets/data/*" {
    capabilities = ["list", "read", "create", "update", "delete"]
}
path "team-secrets/metadata/" {
    capabilities = ["list", "read", "create", "update", "delete"]
}
path "team-secrets/metadata/*" {
    capabilities = ["list", "read", "create", "update", "delete"]
}
EOF

vault policy write mng_approles - <<EOF
path "auth/approle/*" {
    capabilities = ["list", "read", "create", "update", "delete"]
}
EOF

# Add users 
vault write auth/userpass/users/user01 password=user01 token_policies=default,mng_team_secrets,mng_approles

# Enaable Approles
vault auth enable approle

# Get Approle accessor reference
APPROLE_ACCESSOR=$(vault auth list -format=json  | jq -r 'to_entries[] | select( .value.type | test( "approle")) | .value.accessor' )

# Create Policy template for APPROLE users
vault policy write mngd_approle - <<EOF
path "team-secrets/data/approle/{{identity.entity.aliases.${APPROLE_ACCESSOR}.metadata.role_name}}" {
    capabilities = ["list", "read", "create", "update"]
}
path "team-secrets/data/approle/{{identity.entity.aliases.${APPROLE_ACCESSOR}.metadata.role_name}}/*" {
    capabilities = ["list", "read", "create", "update"]
}
path "team-secrets/metadata/approle/{{identity.entity.aliases.${APPROLE_ACCESSOR}.metadata.role_name}}" {
    capabilities = ["list", "read"]
}
path "team-secrets/metadata/approle/{{identity.entity.aliases.${APPROLE_ACCESSOR}.metadata.role_name}}/*" {
    capabilities = ["list", "read"]
}

EOF

# Create a pki App_role
vault write auth/approle/role/grp01 token_policies=default,mngd_approle
vault write auth/approle/role/grp02 token_policies=default,mngd_approle
vault write auth/approle/role/grp03 token_policies=default,mngd_approle
vault write auth/approle/role/grp04 token_policies=default,mngd_approle
