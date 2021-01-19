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
if [ $# -lt 1 ]; then echo "The second argument of this script must be the WEBHOOK_URL environment variable. https://github.com/Encode42/discord-workflows-webhook" && exit; fi

# Check if Ruby is available
if command -v ruby &> /dev/null; then
	echo -e "[Runner]: Ruby is available! Utilizing author name and PR title getter.\\n"
	WORK_DIR=$(dirname "${BASH_SOURCE[0]}")
	USE_RUBY=true
else
	echo -e "[Runner]: Ruby command not found, skipping optional tasks.\\n"
	USE_RUBY=false
fi

# Commit details
COMMITTER_NAME="$GITHUB_ACTOR"
COMMITTER_URL="$GITHUB_SERVER_URL/$COMMITTER_NAME"
COMMITTER_AVATAR="$GITHUB_SERVER_URL/$COMMITTER_NAME.png"
COMMIT_SUBJECT="$(git log -1 "$GITHUB_SHA" --pretty="%s")"
COMMIT_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/commit/$GITHUB_SHA"
COMMIT_URL_ENDPOINT="$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/commits/$GITHUB_SHA"

# Author details
AUTHOR_NAME="$(git log -1 --pretty="%aN")"

# Get the author name
if $USE_RUBY; then
	echo "[Runner]: Sending request to the GitHub API for the commit author's username..."
	AUTHOR_NAME=$(ruby "$WORK_DIR"/ruby/get_author_name.rb "$COMMIT_URL_ENDPOINT")
	echo -e "[Runner]: Sent the request! '$AUTHOR_NAME' is the recieved commit author.\\n"
fi

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
	PULL_REQUEST_TITLE=$PR_NUM
	PULL_REQUEST_ENDPOINT="$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/pulls/$PR_NUM"

	# Get the PR title
	if $USE_RUBY; then
		echo "[Runner]: Sending request to the GitHub API for the PR title..."
		PULL_REQUEST_TITLE=$(ruby "$WORK_DIR"/ruby/get_pull_request_title.rb "$PULL_REQUEST_ENDPOINT")
		echo -e "[Runner]: Sent the request! '$PULL_REQUEST_TITLE' is the recieved pull request title.\\n"
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
			"name": "'"$COMMITTER_NAME"'",
			"icon_url": "'$COMMITTER_AVATAR'",
			"url": "'$COMMITTER_URL'"
		},
		"title": "['"$REPO_NAME"':'"$BRANCH_NAME"'] Build '"$STATUS_MESSAGE"'",
		"url": "'"$ACTION_URL"'",
		"description": "'"[\`${GITHUB_SHA:0:7}\`](${COMMIT_URL})"' '"$COMMIT_SUBJECT"' - '"$AUTHOR_NAME"'"
	}]
}'

for ARG in "$@"; do
	echo -e "[Runner]: Compiled webhook data: $WEBHOOK_DATA\\n"

	# Send the webhook
	echo "[Webhook]: Sending webhook to Discord...";
	(curl --fail --progress-bar -A "GitHub-Actions-Webhook" -H Content-Type:application/json -H X-Author:k3rn31p4nic#8383 -d "${WEBHOOK_DATA//	/ }" "$ARG" \
	&& echo -e "\\n[Webhook]: Successfully sent the webhook.") || echo -e "\\n[Webhook]: Unable to send webhook."
done
