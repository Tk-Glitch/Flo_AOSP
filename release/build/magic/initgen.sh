#!/sbin/sh

#systemcheck
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

if [ -e /system/bin/mpdecision_bck ] ; then
  mv /system/bin/mpdecision_bck /system/bin/mpdecision
fi

if [ -e /system/bin/thermald ] ; then
  mv /system/bin/thermald /system/bin/thermald_bck
fi

if [ ! -d /data/synapse ]; then
   mkdir /data/synapse;
fi

#Import/Generate settings
if [ ! -f /tmp/glitch-settings.conf ];then

   if [ ! -f /sdcard/glitch-settings.conf ]; then
   echo "No backup found. Using default Glitch settings and making a backup."
   cp /tmp/glitch-settings-default.conf /sdcard/glitch-settings.conf
   cp /tmp/glitch-settings-default.conf /tmp/glitch-settings.conf
   fi

   if [ -f /sdcard/glitch-settings.conf ]; then
   echo "Backup found on sdcard. Restoring settings."
   cp /sdcard/glitch-settings.conf /tmp/glitch-settings.conf
   fi

else

   echo "Aroma settings found. Removing existing backup and making a new one."
   if [ -f /sdcard/glitch-settings.conf ]; then
   rm /sdcard/glitch-settings.conf
   fi
   cp /tmp/glitch-settings.conf /sdcard/glitch-settings.conf

fi

wait ${!}

chmod 666 /tmp/glitch-settings.conf

. /tmp/glitch-settings.conf

INIT="/tmp/init.glitch.rc"
l2_opt="l2_opt="$L2_OC;
vdd_uv="vdd_uv="$UV_LEVEL;
null="abc"

#Permissive Selinux
if [ "$PERMISSIVE" == "1" ]; then
  echo "cmdline = console=ttyHSL0,115200,n8 androidboot.hardware=flo user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3 vmalloc=340M enforcing=0 androidboot.selinux=permissive" $l2_opt $vdd_uv $null >> /tmp/cmdline.cfg
else
  echo "cmdline = console=ttyHSL0,115200,n8 androidboot.hardware=flo user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3 vmalloc=340M enforcing=1 androidboot.selinux=enforcing" $l2_opt $vdd_uv $null >> /tmp/cmdline.cfg
fi

####################################################################

echo "on early-init" >> $INIT
echo "" >> $INIT
echo "write /sys/class/graphics/fb0/rgb \"32768 32768 32768\"" >> $INIT
echo "" >> $INIT
echo "on boot" >> $INIT
echo "" >> $INIT

####################################################################

# KSM options
echo "write /sys/kernel/mm/ksm/sleep_millisecs 1000" >> $INIT
echo "write /sys/kernel/mm/ksm/pages_to_scan 256" >> $INIT
echo "write /sys/kernel/mm/ksm/deferred_timer 1" >> $INIT
echo "write /sys/kernel/mm/ksm/run 1" >> $INIT
echo "" >> $INIT

#S2W
echo "write /sys/android_touch/sweep2wake" $S2W >> $INIT

#DT2W
echo "write /sys/android_touch/doubletap2wake" $DT2W >> $INIT

#Shortsweep
echo "write /sys/android_touch/shortsweep" $SHORTSWEEP >> $INIT

#S2W Power key toggle
echo "write /sys/android_touch/pwrkey_suspend" $PWR_KEY >> $INIT

#S2W Magnetic cover toggle
echo "write /sys/android_touch/lid_suspend" $LID_SUS >> $INIT

#S2W/DT2W Timeout
echo "write /sys/android_touch/wake_timeout" $TIMEOUT >> $INIT

#S2S
echo "write /sys/android_touch/sweep2sleep" $S2S >> $INIT

#S2S Options
if [ $PORTRAIT = 1 ]; then
  echo "write /sys/android_touch/orientation 1" >> $INIT
elif [ $LANDSCAPE = 1 ]; then
  echo "write /sys/android_touch/orientation 2" >> $INIT
else
  echo "write /sys/android_touch/orientation 0" >> $INIT
fi

#MC Power Savings
if [ "$MC_POWERSAVE" == "1" ]; then
  echo "write /sys/devices/system/cpu/sched_mc_power_savings 2" >> $INIT
else
  echo "write /sys/devices/system/cpu/sched_mc_power_savings 0" >> $INIT
fi

#Magnetic on/off
if [ "$LID" == "1" ]; then
echo "write /sys/module/lid/parameters/enable_lid 1" >> $INIT
else
echo "write /sys/module/lid/parameters/enable_lid 0" >> $INIT
fi

#Fast Charge
if [ "$FAST_CHARGE" == "1" ]; then
echo "write /sys/kernel/fast_charge/force_fast_charge 1" >> $INIT
else
echo "write /sys/kernel/fast_charge/force_fast_charge 0" >> $INIT
fi

#USB Host mode charging
if [ "$OTGCM" == "1" ]; then
echo "write /sys/module/msm_otg/parameters/usbhost_charge_mode Y" >> $INIT
else
echo "write /sys/module/msm_otg/parameters/usbhost_charge_mode N" >> $INIT
fi

#Battery life extender
if [ "$BLE" == "2" ]; then
  echo "write /sys/devices/i2c-0/0-006a/float_voltage 4200" >> $INIT
elif [ "$BLE" == "3" ]; then
  echo "write /sys/devices/i2c-0/0-006a/float_voltage 4100" >> $INIT
elif [ "$BLE" == "4" ]; then
  echo "write /sys/devices/i2c-0/0-006a/float_voltage 4000" >> $INIT
else
  echo "write /sys/devices/i2c-0/0-006a/float_voltage 4300" >> $INIT
fi

#fsync
if [ "$FSYNC" == "1" ]; then
  echo "write /sys/module/sync/parameters/fsync_enabled N" >> $INIT
else
  echo "write /sys/module/sync/parameters/fsync_enabled Y" >> $INIT
fi

#Backlight dimmer
  echo "write /sys/module/msm_fb/parameters/backlight_dimmer $BLD" >> $INIT

####################################################################

#HOTPLUGDRV
if [ "$HOTPLUGDRV" == "1" ]; then
  echo "write /sys/module/msm_mpdecision/parameters/enabled 0" >> $INIT
  echo "write /sys/module/msm_hotplug/msm_enabled 1" >> $INIT
  echo "write /sys/module/msm_hotplug/io_is_busy 1" >> $INIT
else
  echo "write /sys/module/msm_mpdecision/parameters/enabled 1" >> $INIT
  echo "write /sys/module/msm_hotplug/msm_enabled 0" >> $INIT
fi

#GPU Governor
if [ "$GPU_GOV" == "2" ]; then
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/pwrscale/trustzone/governor simple" >> $INIT
else
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/pwrscale/trustzone/governor ondemand" >> $INIT
fi

echo "" >> $INIT
echo "on property:sys.boot_completed=1" >> $INIT
echo "" >> $INIT

#read-ahead
if [ "$READAHEAD" == "2" ]; then
  echo "write /sys/block/mmcblk0/queue/read_ahead_kb 256" >> $INIT
elif [ "$READAHEAD" == "3" ]; then
  echo "write /sys/block/mmcblk0/queue/read_ahead_kb 512" >> $INIT
elif [ "$READAHEAD" == "4" ]; then
  echo "write /sys/block/mmcblk0/queue/read_ahead_kb 1024" >> $INIT
elif [ "$READAHEAD" == "5" ]; then
  echo "write /sys/block/mmcblk0/queue/read_ahead_kb 2048" >> $INIT
else
  echo "write /sys/block/mmcblk0/queue/read_ahead_kb 128" >> $INIT
fi

#GPU Clock
if [ "$GPU_OC" == "1" ]; then
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/max_gpuclk 320000000" >> $INIT
elif [ "$GPU_OC" == "3" ]; then
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/max_gpuclk 450000000" >> $INIT
elif [ "$GPU_OC" == "4" ]; then
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/max_gpuclk 504000000" >> $INIT
elif [ "$GPU_OC" == "5" ]; then
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/max_gpuclk 545000000" >> $INIT
elif [ "$GPU_OC" == "6" ]; then
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/max_gpuclk 600000000" >> $INIT
elif [ "$GPU_OC" == "7" ]; then
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/max_gpuclk 627000000" >> $INIT
else
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/max_gpuclk 400000000" >> $INIT
fi

#GPU UV
if [ "$GPU_UV" == "2" ]; then
  echo "write /sys/devices/system/cpu/cpufreq/vdd_table/vdd_levels_GPU \"920000 1025000 1125000\"" >> $INIT
elif [ "$GPU_UV" == "3" ]; then
  echo "write /sys/devices/system/cpu/cpufreq/vdd_table/vdd_levels_GPU \"900000 1000000 1100000\"" >> $INIT
elif [ "$GPU_UV" == "4" ]; then
  echo "write /sys/devices/system/cpu/cpufreq/vdd_table/vdd_levels_GPU \"900000 975000 1075000\"" >> $INIT
elif [ "$GPU_UV" == "5" ]; then
  echo "write /sys/devices/system/cpu/cpufreq/vdd_table/vdd_levels_GPU \"900000 950000 1050000\"" >> $INIT
elif [ "$GPU_UV" == "6" ]; then
  echo "write /sys/devices/system/cpu/cpufreq/vdd_table/vdd_levels_GPU \"900000 925000 1025000\"" >> $INIT
elif [ "$GPU_UV" == "7" ]; then
  echo "write /sys/devices/system/cpu/cpufreq/vdd_table/vdd_levels_GPU \"900000 900000 1000000\"" >> $INIT
else
  echo "write /sys/devices/system/cpu/cpufreq/vdd_table/vdd_levels_GPU \"945000 1050000 1150000\"" >> $INIT
fi

#Max CPU_FREQ
echo "write /sys/kernel/msm_limiter/resume_max_freq \"0:$MAXF_CPU0 1:$MAXF_CPU1 2:$MAXF_CPU2 3:$MAXF_CPU3\"" >> $INIT

#MINFREQ
echo "write /sys/kernel/msm_limiter/suspend_min_freq \"0:$MINF 1:$MINF 2:$MINF 3:$MINF\"" >> $INIT

#Max suspend CPU_FREQ
if [ "$SCROFF" == "1" ]; then
  echo "write /sys/kernel/msm_limiter/suspend_max_freq 594000" >> $INIT
elif [ "$SCROFF" == "2" ]; then
  echo "write /sys/kernel/msm_limiter/suspend_max_freq 702000" >> $INIT
elif [ "$SCROFF" == "3" ]; then
  echo "write /sys/kernel/msm_limiter/suspend_max_freq 810000" >> $INIT
elif [ "$SCROFF" == "4" ]; then
  echo "write /sys/kernel/msm_limiter/suspend_max_freq 1026000" >> $INIT
elif [ "$SCROFF" == "5" ]; then
  echo "write /sys/kernel/msm_limiter/suspend_max_freq 1242000" >> $INIT
else
  echo "write /sys/kernel/msm_limiter/suspend_max_freq 1512000" >> $INIT
fi

#CPU governor
if [ "$CPU_GOV" == "1" ]; then
  echo "write /sys/kernel/msm_limiter/scaling_governor \"ondemand\"" >> $INIT
elif [ "$CPU_GOV" == "3" ]; then
  echo "write /sys/kernel/msm_limiter/scaling_governor \"smartmax\"" >> $INIT
elif [ "$CPU_GOV" == "4" ]; then
  echo "write /sys/kernel/msm_limiter/scaling_governor \"intellidemand\"" >> $INIT
elif [ "$CPU_GOV" == "5" ]; then
  echo "write /sys/kernel/msm_limiter/scaling_governor \"intelliactive\"" >> $INIT
elif [ "$CPU_GOV" == "6" ]; then
  echo "write /sys/kernel/msm_limiter/scaling_governor \"elementalx\"" >> $INIT
elif [ "$CPU_GOV" == "7" ]; then
  echo "write /sys/kernel/msm_limiter/scaling_governor \"conservative\"" >> $INIT
else
  echo "write /sys/kernel/msm_limiter/scaling_governor \"interactive\"" >> $INIT
fi

#THERMAL
if [ "$THERM" == "1" ]; then
  echo "write /sys/module/msm_thermal/parameters/limit_temp_degC 65" >> $INIT
  echo "write /sys/module/msm_thermal/parameters/core_limit_temp_degC 75" >> $INIT
  echo "write /sys/module/msm_thermal/parameters/freq_control_mask 12" >> $INIT
  echo "write /sys/module/msm_thermal/parameters/core_control_mask 8" >> $INIT
  echo "write /sys/module/msm_thermal/parameters/thermal_limit_high 20" >> $INIT
  echo "write /sys/module/msm_thermal/parameters/thermal_limit_low 5" >> $INIT
elif [ "$THERM" == "2" ]; then
  echo "write /sys/module/msm_thermal/parameters/limit_temp_degC 80" >> $INIT
  echo "write /sys/module/msm_thermal/parameters/core_limit_temp_degC 90" >> $INIT
  echo "write /sys/module/msm_thermal/parameters/freq_control_mask 12" >> $INIT
  echo "write /sys/module/msm_thermal/parameters/core_control_mask 8" >> $INIT
  echo "write /sys/module/msm_thermal/parameters/thermal_limit_high 20" >> $INIT
  echo "write /sys/module/msm_thermal/parameters/thermal_limit_low 5" >> $INIT
else
  echo "write /sys/module/msm_thermal/parameters/limit_temp_degC 70" >> $INIT
  echo "write /sys/module/msm_thermal/parameters/core_limit_temp_degC 80" >> $INIT
  echo "write /sys/module/msm_thermal/parameters/freq_control_mask 12" >> $INIT
  echo "write /sys/module/msm_thermal/parameters/core_control_mask 8" >> $INIT
  echo "write /sys/module/msm_thermal/parameters/thermal_limit_high 20" >> $INIT
  echo "write /sys/module/msm_thermal/parameters/thermal_limit_low 5" >> $INIT
fi

#I/O scheduler // Triggers too early on LOS14.1
if [ "$IOSCHED" == "1" ]; then
  echo "write /sys/block/mmcblk0/queue/scheduler cfq" >> $INIT
elif [ "$IOSCHED" == "2" ]; then
  echo "write /sys/block/mmcblk0/queue/scheduler fiops" >> $INIT
elif [ "$IOSCHED" == "3" ]; then
  echo "write /sys/block/mmcblk0/queue/scheduler sio" >> $INIT
elif [ "$IOSCHED" == "5" ]; then
  echo "write /sys/block/mmcblk0/queue/scheduler noop" >> $INIT
elif [ "$IOSCHED" == "6" ]; then
  echo "write /sys/block/mmcblk0/queue/scheduler bfq" >> $INIT
elif [ "$IOSCHED" == "7" ]; then
  echo "write /sys/block/mmcblk0/queue/scheduler zen" >> $INIT
else
  echo "write /sys/block/mmcblk0/queue/scheduler deadline" >> $INIT
fi

#END
