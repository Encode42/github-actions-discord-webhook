# Discord Webhook for Github Actions
**Modified to have the same style as the default GitHub webhook.**  
This is mainly for my own personal use! There will be little to no support provided.

## Setup
1. In Github secrets, add a `WEBHOOK_URL` variable with the Discord web hook URL.
2. Inside your workflow file, add this snippet after the build-critical task:

    ```yaml
        - uses: actions/setup-ruby@v1
        - name: Send Webhook Notification
          if: always()
          run: |
            git clone https://github.com/Encode42/discord-workflows-webhook.git webhook
            bash webhook/send.sh ${{ job.status }} ${{ secrets.WEBHOOK_URL }}
          shell: bash
    ```

    <sub>To see a working example, look at [this workflow file](https://github.com/Encode42/MatrixChecks-Plugin/blob/main/.github/workflows/run.yml).</sub>  
    <sub>Note: Excluding the Ruby setup action will automatically disable the PR title getter.</sub>
3. That's all! Notifications will be sent on every workflow run.