# scripts
This is my storage for useful scripts I had to develop for various tasks.

# Scripts

- [Export banned](server/export_banned.sh): Export data about banned IPs from a server (parsing Fail2ban client statuses).
  To run in CRON root every 6 hours:
    ```bash
    0 */6 * * * /home/TARGET_USER/utils/export_banned.sh export >> /dev/null 2>> /home/TARGET_USER/utils/cron_errors.log
    ```