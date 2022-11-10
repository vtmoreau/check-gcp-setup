#! /bin/sh

# Check gcloud is installed
if ! gcloud -v 1>/dev/null 2>&1 ; then 
    echo '❌ gcloud is not installed on this computer, please install gcloud'
    exit 1
else
    echo '✅ gcloud installed'
fi

# Check gcloud has auth
auth_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
if  [ -z "$auth_account" ] ; then
    echo '❌ gcloud has no authenticated active account'
    echo 'Please run: gcloud auth login'
    exit 1
else
    echo "✅ authenticated as: $auth_account"
fi

# Check set account
config_account=$(gcloud config get account)
if [ -z "$config_account" ]  ; then
    echo '❌ gcloud has not account set in config'
    echo 'Please run: gcloud config set account <your-gcp-account-email>'
    exit 1
else
    echo "✅ active account set as: $config_account"
fi

# Check set project
config_project=$(gcloud config get project)
if  [ -z "$config_project" ] ; then
    echo '❌ gcloud has not project set in config'
    echo 'Please run: gcloud config set project <your-gcp-project-id>'
    exit 1
else
    echo "✅ active project set as: $config_project"
fi

# Check active billing account
# Need gcloud alpha :'(
# if gcloud alpha billing projects describe $(gcloud config get project) --format"value(billingEnabled)" True...
# fi

# Check active service account
service_accounts_number=$(gcloud iam service-accounts list | wc -l)
if [ "$service_accounts_number" -le 2 ] ; then
    echo '❌ no service account exist for this project, please create one'
    exit 1
else
    echo '✅ found at least 1 service account'
fi

# Check presence of credentials
if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo '❌ Unset environment variable GOOGLE_APPLICATION_CREDENTIALS'
    echo 'Please add to your ~/.aliases: export GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/your/credentials.json'
else
    echo "✅ credentials file found in: $GOOGLE_APPLICATION_CREDENTIALS"
fi

# Check validity of credentials
creds_type=$(cat "$GOOGLE_APPLICATION_CREDENTIALS" | jq '.type')
creds_account=$(cat "$GOOGLE_APPLICATION_CREDENTIALS" | jq '.client_email')
if [ "$creds_type" = 'service_account' ]; then
    echo '❌ Unset environment variable GOOGLE_APPLICATION_CREDENTIALS'
    echo 'Please add to your ~/.aliases: export GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/your/credentials.json'
else
    echo "✅ credentials are for the service account: $creds_account"
fi

# Check service account roles
service_account_roles=$(gcloud projects get-iam-policy "$config_project" \
                        --flatten="bindings[].members" \
                        --format='table(bindings.role)' \
                        --filter="bindings.members:$creds_account")
if ! echo "$service_account_roles" | grep -q 'roles/owner'; then
    echo '❌ your service account has not the owner role'
else
    echo '✅ your service account has the owner role'
fi
