# Discord Webhook for Github Actions
**Modified to have the same style as the default GitHub webhook.**

Note: This is mainly for my own personal use! There will be no support provided.

## Setup
1. In Github secrets, add a `WEBHOOK_URL` variable with the Discord web hook URL
1. In your Github actions yml file, add this to reference the variable you just created:
    - To see a real example, visit [here](https://github.com/Encode42/MatrixChecks-Plugin/blob/9b53a421c036b7f6197f6a5052a425a96eaa343d/.github/workflows/run.yml#L48).
    ```yaml
        - uses: actions/setup-ruby@v1
        - name: Send Webhook Notification
          if: always()
          env:
            JOB_STATUS: ${{ job.status }}
            WEBHOOK_URL: ${{ secrets.WEBHOOK_URL }}
            HOOK_OS_NAME: ${{ runner.os }}
            WORKFLOW_NAME: ${{ github.workflow }}
          run: |
            git clone https://github.com/Encode42/discord-workflows-webhook.git webhook
            bash webhook/send.sh $JOB_STATUS $WEBHOOK_URL
          shell: bash
    ```
1. Enjoy!
