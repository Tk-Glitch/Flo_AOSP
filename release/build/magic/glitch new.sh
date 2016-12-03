#!/system/bin/sh

#Touch Firmware
TFW="`cat /sys/devices/i2c-3/3-0010/vendor`"
echo TouchFW: $TFW >> $KERNEL_LOGFILE;

#fstrim
fstrim -v /cache | tee -a $KERNEL_LOGFILE;
fstrim -v /data | tee -a $KERNEL_LOGFILE;

#GPU Governor settings
if [ "`grep GPU_GOV=2 $KERNEL_CONF`" ]; then
  echo interactive > /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/pwrscale/trustzone/governor;
  echo Interactive GPU Governor >> $KERNEL_LOGFILE;
elif [ "`grep GPU_GOV=3 $KERNEL_CONF`" ]; then
  echo performance > /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/pwrscale/trustzone/governor;
  echo Performance GPU Governor >> $KERNEL_LOGFILE;
else
  echo ondemand > /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/pwrscale/trustzone/governor;
  echo Ondemand GPU Governor >> $KERNEL_LOGFILE;
fi

#CPU governor
if [ "`grep CPU_GOV=2 $KERNEL_CONF`" ]; then
  governor=interactive
elif [ "`grep CPU_GOV=3 $KERNEL_CONF`" ]; then
  governor=intellidemand
elif [ "`grep CPU_GOV=4 $KERNEL_CONF`" ]; then
  governor=smartmax
elif [ "`grep CPU_GOV=5 $KERNEL_CONF`" ]; then
  governor=smartmax_eps
elif [ "`grep CPU_GOV=6 $KERNEL_CONF`" ]; then
  governor=intelliactive
elif [ "`grep CPU_GOV=7 $KERNEL_CONF`" ]; then
  governor=conservative
else
  governor=ondemand
fi
  echo $governor > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
  echo CPU Governor: $governor >> $KERNEL_LOGFILE;

#Backup settings to sdcard
 cp /system/etc/glitch-settings.conf /sdcard/glitch-settings.conf
 echo "Settings backup created on sdcard root" >> $KERNEL_LOGFILE;

###########SYS

# **************************************************************
# Add Synapse support
# **************************************************************

SYN=/data/synapse;
BB=/sbin/busybox;
UCI_CONFIG=$SYN/config.json;
DEBUG=$SYN/debug;
UCI_FILE=$SYN/uci;
UCI_XBIN=/system/xbin/uci;

# Delete known files that re-create uci config

if [ -e "/data/ak/ak-post-boot.sh" ]; then
	$BB rm -f /data/ak/ak-post-boot.sh #ak
	$BB rm -f /sbin/post-init.sh #neobuddy89
fi

# Delete default uci config in case kernel has one already to avoid duplicates.

if [ -e "/sbin/uci" ]; then
	$BB rm -f /sbin/uci
fi

# Delete all debug files so it can be re-created on boot.

$BB rm -f $DEBUG/*

# Reset profiles to default

$BB echo "Custom" > $SYN/files/gamma_prof
$BB echo "Custom" > $SYN/files/lmk_prof
$BB echo "Custom" > $SYN/files/sound_prof
$BB echo "Custom" > $SYN/files/speaker_prof
$BB echo "0" > $SYN/files/volt_prof;
$BB echo "0" > $SYN/files/dropcaches_prof;

# Symlink uci file to xbin in case it's not found.

if [ ! -e $UCI_XBIN ]; then
	$BB mount -o remount,rw /system
	$BB mount -t rootfs -o remount,rw rootfs

	$BB chmod 755 $UCI_FILE
	$BB ln -s $UCI_FILE $UCI_XBIN
	$BB chmod 755 $UCI_XBIN

	$BB mount -t rootfs -o remount,ro rootfs
	$BB mount -o remount,ro /system
fi

# If uci files does not have 755 permissions, set permissions.

if [ `$BB stat -c %a $UCI_FILE` -lt "755" ]; then
	$BB chmod 755 $UCI_FILE
fi

if [ `$BB stat -c %a $UCI_XBIN` -lt "755" ]; then
	$BB mount -o remount,rw /system
	$BB mount -t rootfs -o remount,rw rootfs
	$BB chmod 755 $UCI_XBIN
	$BB mount -t rootfs -o remount,ro rootfs
	$BB mount -o remount,ro /system
fi

# Reset uci config so it can be re-created on boot.

$UCI_XBIN reset;
$BB sleep 1;
$UCI_XBIN;
##########/SYS

exit 0
