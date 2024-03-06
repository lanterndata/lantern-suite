#!/bin/bash

cd /tmp
psql -Atq -U postgres -d postgres -c "SELECT concat('\"', usename, '\" \"', passwd, '\"') FROM pg_shadow" > userlist.txt

cat <<EOF > pgbouncer.ini
[databases]
# connect to postgres via domain socket
* = host=/var/run/postgresql/ port=5432

[pgbouncer]
# Connection settings
listen_addr = *
listen_port = 6432
auth_type = scram-sha-256
auth_user = postgres
auth_file = userlist.txt
pidfile= pidfile.txt

logfile = pgbouncer.log
pidfile = pgbouncer.pid
admin_users = postgres
stats_users = postgres
pool_mode = session
ignore_startup_parameters = extra_float_digits
max_client_conn = 2000
default_pool_size = 10
reserve_pool_timeout = 3
server_lifetime = 300
server_idle_timeout = 120
server_connect_timeout = 5
server_login_retry = 1
query_wait_timeout = 60
client_login_timeout = 60
EOF

pgbouncer -d pgbouncer.ini
echo "Done initalizing pgbouncer"