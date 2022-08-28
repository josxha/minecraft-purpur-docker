#!/bin/sh
set -e
exec java -jar -Xms$RAM -Xmx$RAM $JAVAFLAGS /minecraft/purpur.jar --nojline nogui