#!/bin/bash
# This original source of this code: https://github.com/DiscordHooks/travis-ci-discord-webhook

# Get the build status
case ${1,,} in
  "success" )
    EMBED_COLOR=38912
    STATUS_MESSAGE="passed"
    ;;

  "failure" )
    EMBED_COLOR=16525609
    STATUS_MESSAGE="failed"
    ;;

  * )
    EMBED_COLOR=2105893
    STATUS_MESSAGE="unknown"
    ;;
esac

# Check for the webhook argument
shift
if [ $# -lt 1 ]; then echo -e "The second argument of this script must be the WEBHOOK_URL environment variable. https://github.com/Encode42/discord-workflows-webhook" && exit; fi

# Author details
AUTHOR_NAME="$GITHUB_ACTOR"
AUTHOR_URL="$GITHUB_SERVER_URL/$AUTHOR_NAME"
AUTHOR_AVATAR="$GITHUB_SERVER_URL/$AUTHOR_NAME.png"

# Commit details
COMMITTER_NAME="$(git log -1 "$GITHUB_SHA" --pretty="%cN")"
COMMIT_SUBJECT="$(git log -1 "$GITHUB_SHA" --pretty="%s")"
COMMIT_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/commit/$GITHUB_SHA"

# Branch details
REPO_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY"
REPO_NAME="$(echo "$GITHUB_REPOSITORY" | sed 's/^[^\/]*\///')"
BRANCH_NAME="$(echo "$GITHUB_REF" | sed 's/^[^/]*\/[^/]*\///g')"
BRANCH_OR_PR_URL="$REPO_URL/tree/$BRANCH_NAME"
ACTION_URL="$REPO_URL/actions/runs/$GITHUB_RUN_ID"

# PR details
if [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
	PR_NUM=$(sed 's/\/.*//g' <<< "$BRANCH_NAME")
	BRANCH_OR_PR_URL="$REPO_URL/pull/$PR_NUM"
	BRANCH_NAME="#${PR_NUM}"
	PULL_REQUEST_ENDPOINT="$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/pulls/$PR_NUM"

	# Check if the Ruby command is set up
	# If not, PR title = PR number
	if command -v ruby &> /dev/null; then
		WORK_DIR=$(dirname "${BASH_SOURCE[0]}")
		PULL_REQUEST_TITLE=$(ruby "$WORK_DIR"/get_pull_request_title.rb "$PULL_REQUEST_ENDPOINT")
	else
		echo -e "Ruby command not found, PR title getting skipped..."
		PULL_REQUEST_TITLE=$PR_NUM
	fi

	COMMIT_SUBJECT=$PULL_REQUEST_TITLE
	ACTION_URL="$BRANCH_OR_PR_URL/checks"
fi

# Compile the webhook data
WEBHOOK_DATA='{
  "avatar_url": "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png",
  "embeds": [{
    "color": '$EMBED_COLOR',
    "author": {
      "name": "'"$AUTHOR_NAME"'",
      "icon_url": "'$AUTHOR_AVATAR'",
      "url": "'$AUTHOR_URL'"
    },
    "title": "['"$REPO_NAME"':'"$BRANCH_NAME"'] Build '"$STATUS_MESSAGE"'",
    "url": "'"$ACTION_URL"'",
    "description": "'"[\`${GITHUB_SHA:0:7}\`](${COMMIT_URL})"' '"$COMMIT_SUBJECT"' - '"$COMMITTER_NAME"'"
  }]
}'

for ARG in "$@"; do
  echo -e "[Webhook]: Compiled JSON webhook data: $WEBHOOK_DATA\\n"

  # Send the webhook
  echo -e "[Webhook]: Sending webhook to Discord...\\n";
  (curl --fail --progress-bar -A "GitHub-Actions-Webhook" -H Content-Type:application/json -H X-Author:k3rn31p4nic#8383 -d "${WEBHOOK_DATA//	/ }" "$ARG" \
  && echo -e "\\n[Webhook]: Successfully sent the webhook.") || echo -e "\\n[Webhook]: Unable to send webhook."
done
