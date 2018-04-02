echo "Make sure alter the permissions of the /var/log/potoo folder to be open to the logging user"
echo "Make sure to run this script as root since /etc/logrotate.d requires root"
APP=$1

CONF_DIR="/etc/logrotate.d"
CONF_FILE=$(printf "/etc/logrotate.d/%s.conf" $APP)
LOG_DIR=$(printf "/var/log/potoo/%s" $APP)
LOG_FILE=$(printf "%s/%s.log" $LOG_DIR $APP)
LOG_FILE_WEEKLY=$(printf "%s/%s.weekly.log" $LOG_DIR $APP)
LOG_FILE_MONTHLY=$(printf "%s/%s.monthly.log" $LOG_DIR $APP)

if [ ! -d $LOG_DIR ]; then
    # we need to make the logs entry
    mkdir -p $LOG_DIR

    if [ ! -d $CONF_DIR ]; then
        mkdir -p $CONF_DIR
    fi

    cat << END_TEXT > $CONF_FILE
# https://unix.stackexchange.com/questions/116996/use-logrotate-to-store-7-daily-4-weekly-and-12-yearly-db-backups
# daily (son)
"/var/log/potoo/$APP.log" {
    daily
    rotate 7
    missingok
    copy
    compress
}
# weekly (father)
"/var/log/potoo/$APP.weekly.log" {
    weekly
    rotate 4
    missingok
    copy
    dateext
    dateformat %Y-%m-%d.
    compress
}
# monthly (grandfather)
"/var/log/potoo/$APP.monthly.log" {
    monthly
    rotate 12
    missingok
    copy
    dateformat %Y-%m-%d.
    compress
}
END_TEXT

    touch $LOG_FILE
    crontab -l >> /tmp/cronpotoo
    printf "0 0 * * 0 cp /var/log/potoo/%s.log /var/log/potoo/%s.weekly.log\n" $APP $APP >> /tmp/cronpotoo
    printf "0 1 1 * * cp /var/log/potoo/%s.log /var/log/potoo/%s.monthly.log\n" $APP $APP >> /tmp/cronpotoo
    crontab /tmp/cronpotoo
    rm /tmp/cronpotoo

fi

echo "Now make sure your script is on a cron and logging to the right file"
