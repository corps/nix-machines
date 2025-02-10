#!/usr/bin/env nix-shell
#! nix-shell -i bash -p jq

API_URL="https://api.mistral.ai/v1/completions"
API_KEY="YOUR_API_KEY"
MODEL="open-mistral-nemo-2407"
MAX_TOKENS="1024"
CHAT_LOG=/tmp/mistral.chat.log
touch $CHAT_LOG
CHAT_HISTORY="$(cat $CHAT_LOG)"

while getopts ":v" opt; do
  case $opt in
  c)
    echo "" >$CHAT_LOG
    CHAT_HISTORY='[{"role": "system", "content": "You are a professional software engineer."}]'
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    exit 1
    ;;
  esac
done

shift $((OPTIND - 1))
USER_MESSAGE="$(jq -n --arg message "$1" '[{"role": "user", "content": $message}]')"

CHAT_HISTORY="$(jq -s '[.]]' <(echo "$CHAT_HISTORY
$USER_MESSAGE"))"

# Use jq to format the JSON data
# JSON_DATA="$(jq -n \
#   --argjson max_tokens "$MAX_TOKENS" \
#   --argjson messages "$CHAT_HISTORY" \
#   --arg model "$MODEL" \
#   '{
#     "model": $model,
#     "messages": $messages,
#     "max_tokens": $max_tokens
#   }')"

echo $CHAT_HISTORY

# curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $MISTRAL_API_KEY" -d "$JSON_DATA" "$API_URL"
