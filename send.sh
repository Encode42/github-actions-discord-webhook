#!/bin/bash
# This original source of this code: https://github.com/DiscordHooks/travis-ci-discord-webhook
# The same functionality from TravisCI is needed for Github Actions
#
# For info on the GITHUB prefixed variables, visit:
# https://help.github.com/en/articles/virtual-environments-for-github-actions#environment-variables

# More info: https://www.gnu.org/software/bash/manual/bash.html#Shell-Parameter-Expansion
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

shift

if [ $# -lt 1 ]; then
  echo -e "WARNING!!\nYou need to pass the WEBHOOK_URL environment variable as the second argument to this script.\nFor details & guide, visit: https://github.com/DiscordHooks/github-actions-discord-webhook" && exit
fi

AUTHOR_NAME="$(git log -1 "$GITHUB_SHA" --pretty="%aN")"
AUTHOR_URL="https://github.com/$AUTHOR_NAME"
COMMITTER_NAME="$(git log -1 "$GITHUB_SHA" --pretty="%cN")"
COMMIT_SUBJECT="$(git log -1 "$GITHUB_SHA" --pretty="%s")"
COMMIT_MESSAGE="$(git log -1 "$GITHUB_SHA" --pretty="%b")" | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g'
COMMIT_URL="https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA"

AVATAR="https://github.com/$AUTHOR_NAME.png"

# If, for example, $GITHUB_REF = refs/heads/feature/example-branch
# Then this sed command returns: feature/example-branch
BRANCH_NAME="$(echo $GITHUB_REF | sed 's/^[^/]*\/[^/]*\///g')"
REPO_URL="https://github.com/$GITHUB_REPOSITORY"
BRANCH_OR_PR="Branch"
BRANCH_OR_PR_URL="$REPO_URL/tree/$BRANCH_NAME"
ACTION_URL="$COMMIT_URL/checks"
COMMIT_OR_PR_URL=$COMMIT_URL
if [ "$AUTHOR_NAME" == "$COMMITTER_NAME" ]; then
  CREDITS="$AUTHOR_NAME authored & committed"
else
  CREDITS="$AUTHOR_NAME authored & $COMMITTER_NAME committed"
fi

if [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
	BRANCH_OR_PR="Pull Request"
	
	PR_NUM=$(sed 's/\/.*//g' <<< $BRANCH_NAME)
	BRANCH_OR_PR_URL="$REPO_URL/pull/$PR_NUM"
	BRANCH_NAME="#${PR_NUM}"
	
	# Call to GitHub API to get PR title
	PULL_REQUEST_ENDPOINT="https://api.github.com/repos/$GITHUB_REPOSITORY/pulls/$PR_NUM"
	
	WORK_DIR=$(dirname ${BASH_SOURCE[0]})
	PULL_REQUEST_TITLE=$(ruby $WORK_DIR/get_pull_request_title.rb $PULL_REQUEST_ENDPOINT)
	
	COMMIT_SUBJECT=$PULL_REQUEST_TITLE
	COMMIT_MESSAGE="Pull Request #$PR_NUM"
	ACTION_URL="$BRANCH_OR_PR_URL/checks"
	COMMIT_OR_PR_URL=$BRANCH_OR_PR_URL
fi

TIMESTAMP=$(date -u +%FT%TZ)
WEBHOOK_DATA='{
  "avatar_url": "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png",
  "embeds": [ {
    "color": '$EMBED_COLOR',
    "author": {
      "name": "'"$COMMITTER_NAME"'",
      "icon_url": "'$AVATAR'",
      "url": "'$AUTHOR_URL'"
    },
    "title": "['"$(echo $GITHUB_REPOSITORY | sed 's/^[^\/]*\///')"':'"$BRANCH_NAME"'] Build '"$STATUS_MESSAGE"'",
    "url": "'"$REPO_URL"'/actions/runs/'"$GITHUB_RUN_ID"'",
    "description": "'"[\`${GITHUB_SHA:0:7}\`](${COMMIT_URL})"' '"$COMMIT_SUBJECT"' - '"$COMMITTER_NAME"'"
  } ]
}'

for ARG in "$@"; do
  echo -e "[Webhook]: Sending webhook to Discord...\\n";
  echo -e "$WEBHOOK_DATA"

  (curl --fail --progress-bar -A "GitHub-Actions-Webhook" -H Content-Type:application/json -H X-Author:k3rn31p4nic#8383 -d "${WEBHOOK_DATA//	/ }" "$ARG" \
  && echo -e "\\n[Webhook]: Successfully sent the webhook.") || echo -e "\\n[Webhook]: Unable to send webhook."
done
