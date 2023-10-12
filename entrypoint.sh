#!/bin/bash

set -e

if [ ! -z "$WALLARM_API_TOKEN" ]; then
	echo "Wallarm API Token is set, starting services"
	# Configure PORT in nginx config
	sed -i "s/\$PORT/$PORT/g" /etc/nginx/sites-available/default
	# Register Wallarm node in the cloud
	/opt/wallarm/register-node --token "$WALLARM_API_TOKEN" -H "$WALLARM_API_HOST" --labels "$WALLARM_LABELS"
	# Read default Wallarm environment variables
	export $(sed -e 's/=\(.*\)/="\1"/g' /opt/wallarm/env.list | grep -v "#" | xargs)
	# Export $PORT as $NGINX_PORT (required for the `export-metrics` script)
	export NGINX_PORT="$PORT"
	# Read user-set Wallarm variables
	[ -s /etc/wallarm-override/env.list ] && export $(sed -e 's/=\(.*\)/="\1"/g' /etc/wallarm-override/env.list | grep -v "#" | xargs)
	# Launch all Wallarm services and nginx under supervisord in the background
	/opt/wallarm/usr/bin/python3.8 /opt/wallarm/usr/bin/supervisord -c /opt/wallarm/etc/supervisord.conf
else
	echo "Wallarm API Token is not set, just executing CMD"
fi

# Execute the CMD command
exec "$@"