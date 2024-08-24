#!/bin/bash

# 環境変数の設定
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RESOURCE_GROUP_NAME=<任意のリソースグループ名>
LOCATION="eastus"
HUB_NAME=<任意のHub名>
PROJECT_NAME=<任意のプロジェクト名>
OPENAI_SERVICE_NAME=<任意のOpenAIのサービス名>
SEARCH_SERVICE_NAME=<任意のAI Searchのサービス名>

# リソースグループの作成
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# AI Hub の作成
az ml workspace create --kind hub --resource-group $RESOURCE_GROUP_NAME --name $HUB_NAME --location $LOCATION

# 作成された Hub のリソース ID を取得
HUB_RESOURCE_ID=$(az ml workspace show --name $HUB_NAME --resource-group $RESOURCE_GROUP_NAME --query "id" -o tsv)

# AI プロジェクトの作成
az ml workspace create --kind project --hub-id $HUB_RESOURCE_ID --resource-group $RESOURCE_GROUP_NAME --name $PROJECT_NAME

# Azure OpenAI サービスの作成
az cognitiveservices account create \
  --name $OPENAI_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --kind AIServices \
  --sku S0 \
  --location $LOCATION

# Azure Cognitive Search サービスの作成
az search service create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $SEARCH_SERVICE_NAME \
  --sku Standard \
  --location $LOCATION

# text-embedding-ada-002 の作成
az cognitiveservices account deployment create \
  --name $OPENAI_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --deployment-name text-embedding-ada-002 \
  --model-name text-embedding-ada-002 \
  --model-version "2" \
  --model-format OpenAI \
  --sku-capacity "60" \
  --sku-name "Standard"

# gpt-4o-mini の作成
az cognitiveservices account deployment create \
  --name $OPENAI_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --deployment-name gpt-4o-mini \
  --model-name gpt-4o-mini \
  --model-version "2024-07-18" \
  --model-format OpenAI \
  --sku-capacity "100" \
  --sku-name "Standard"


# Azure Cognitive Searchのシステム割り当てマネージドIDを有効にする
az resource update \
    --name $SEARCH_SERVICE_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --resource-type "Microsoft.Search/searchServices" \
    --set identity.type=SystemAssigned

# Azure Cognitive SearchのプリンシパルIDを取得
SEARCH_PRINCIPAL_ID=$(az resource show \
    --name $SEARCH_SERVICE_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --resource-type "Microsoft.Search/searchServices" \
    --query "identity.principalId" \
    --output tsv)

# Azure OpenAIのシステム割り当てマネージドIDを有効にする
az resource update \
    --name $OPENAI_SERVICE_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --resource-type "Microsoft.CognitiveServices/accounts" \
    --set identity.type=SystemAssigned

# Azure OpenAIのプリンシパルIDを取得
OPENAI_PRINCIPAL_ID=$(az resource show \
    --name $OPENAI_SERVICE_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --resource-type "Microsoft.CognitiveServices/accounts" \
    --query "identity.principalId" \
    --output tsv)

# Azure Cognitive Search に必要なロールを割り当て
az role assignment create \
    --assignee $SEARCH_PRINCIPAL_ID \
    --role "Cognitive Services Contributor" \
    --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.CognitiveServices/accounts/$OPENAI_SERVICE_NAME

# Azure Cognitive Search に必要なロールを割り当て
az role assignment create \
    --assignee $SEARCH_PRINCIPAL_ID \
    --role "Cognitive Services OpenAI Contributor" \
    --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.CognitiveServices/accounts/$OPENAI_SERVICE_NAME

# Azure OpenAI に必要なロールを割り当て
az role assignment create \
    --assignee $OPENAI_PRINCIPAL_ID \
    --role "Cognitive Services Contributor" \
    --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.CognitiveServices/accounts/$OPENAI_SERVICE_NAME

# (オプション) Azure OpenAIにCognitive Services Usages Reader ロールを割り当て
az role assignment create \
    --assignee $SEARCH_PRINCIPAL_ID \
    --role "Cognitive Services Usages Reader" \
    --scope /subscriptions/$SUBSCRIPTION_ID

# エンドポイントとAPIキーの取得
OPENAI_ENDPOINT=$(az cognitiveservices account show --name $OPENAI_SERVICE_NAME --resource-group $RESOURCE_GROUP_NAME --query "properties.endpoint" -o tsv)
OPENAI_API_KEY=$(az cognitiveservices account keys list --name $OPENAI_SERVICE_NAME --resource-group $RESOURCE_GROUP_NAME --query "key1" -o tsv)

SEARCH_ENDPOINT=https://$SEARCH_SERVICE_NAME.search.windows.net
SEARCH_API_KEY=$(az search admin-key show --service-name $SEARCH_SERVICE_NAME --resource-group $RESOURCE_GROUP_NAME --query "primaryKey" -o tsv)


# .env ファイルに環境変数を書き込む
cat <<EOL > .env
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
AZURE_RESOURCE_GROUP=$RESOURCE_GROUP_NAME
AZUREAI_HUB_NAME=$HUB_NAME
AZUREAI_PROJECT_NAME=$PROJECT_NAME
AZURE_OPENAI_CONNECTION_NAME=$OPENAI_SERVICE_NAME
AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT
AZURE_OPENAI_API_KEY=$OPENAI_API_KEY
AZURE_SEARCH_CONNECTION_NAME=$SEARCH_SERVICE_NAME
AZURE_SEARCH_ENDPOINT="https://$SEARCH_SERVICE_NAME.search.windows.net"
AZURE_OPENAI_API_VERSION="2023-03-15-preview"
AZURE_OPENAI_CHAT_DEPLOYMENT="gpt-4o-mini"
AZURE_OPENAI_EMBEDDING_DEPLOYMENT="text-embedding-ada-002"
AZURE_OPENAI_EVALUATION_DEPLOYMENT="gpt-4o-mini"
AZURE_OPENAI_CONNECTION_NAME=<OpenAI の接続名>
AZURE_SEARCH_CONNECTION_NAME=<AI Search の接続名>
AZUREAI_SEARCH_INDEX_NAME=<AI Serarh のインデックス名>
EOL

cat <<EOL > connection/openai.yml
\$schema: https://azuremlschemas.azureedge.net/promptflow/latest/AzureOpenAIConnection.schema.json
name: "openai_connection"
type: azure_open_ai
api_key: "$OPENAI_API_KEY"
api_base: "$OPENAI_ENDPOINT"
api_type: "azure"
api_version: "2024-02-01"
EOL

cat <<EOL > connection/search.yml
\$schema: https://azuremlschemas.azureedge.net/promptflow/latest/CognitiveSearchConnection.schema.json
name: "search_connection"
type: cognitive_search
api_key: "$SEARCH_API_KEY"
api_base: "$SEARCH_ENDPOINT"
api_version: "2023-11-01"
EOL

echo "AI Hub and Project creation completed."

