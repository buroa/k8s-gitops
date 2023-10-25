pragma journal_mode=memory;

-- Description: Prune old messages from the database
-- https://github.com/thelounge/thelounge/wiki/Purging-logs-older-than-X-days
delete from messages where time < strftime('%s', datetime('now', '-7 day'))*1000;

VACUUM;