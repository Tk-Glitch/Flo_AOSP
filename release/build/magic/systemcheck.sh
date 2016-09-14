#!/sbin/sh

if [ ! -f /system/xbin/busybox ]; then
   cp /tmp/busybox /system/xbin/busybox;
   chmod 755 /system/xbin/busybox;
   /system/xbin/busybox --install -s /system/xbin
fi

if [ ! -d /system/etc/init.d ]; then
   if [ -f /system/etc/init.d ]; then
      mv /system/etc/init.d /system/etc/init.d.bak;
   fi
   mkdir /system/etc/init.d;
fi

if [ ! -f /sdcard/glitch-settings.conf ]; then
   echo "No backup found. Using default Glitch settings.";
   cp /tmp/glitch-settings-default.conf /sdcard/glitch-settings.conf;
else
   echo "Backup found.";
fi
