#!/sbin/sh

#Build config file
CONFIGFILE="/tmp/init.glitch.rc"
BACKUP="/sdcard/.glitch.backup"

echo "on early-init" >> $CONFIGFILE
echo "" >> $CONFIGFILE
echo "write /sys/class/graphics/fb0/rgb \"32768 32768 32768\"" >> $CONFIGFILE
echo "" >> $CONFIGFILE
echo "on boot" >> $CONFIGFILE
echo "" >> $CONFIGFILE

#Permissive Selinux
PERMISSIVE=`grep "item.0.7" /tmp/aroma/misc.prop | cut -d '=' -f2`
if [ "$PERMISSIVE" = 1 ]; then
  echo "write /sys/fs/selinux/enforce 0" >> $CONFIGFILE;
else
  echo "write /sys/fs/selinux/enforce 1" >> $CONFIGFILE;
fi

# KSM options
echo "write /sys/kernel/mm/ksm/sleep_millisecs 1000" >> $CONFIGFILE
echo "write /sys/kernel/mm/ksm/pages_to_scan 256" >> $CONFIGFILE
echo "write /sys/kernel/mm/ksm/deferred_timer 1" >> $CONFIGFILE
echo "write /sys/kernel/mm/ksm/run 1" >> $CONFIGFILE
echo "" >> $CONFIGFILE

if [ ! -e /tmp/aroma/gest.prop ]; then
  touch /tmp/aroma/gest.prop;
fi

#S2W
SR=`grep "item.1.1" /tmp/aroma/gest.prop | cut -d '=' -f2`
SL=`grep "item.1.2" /tmp/aroma/gest.prop | cut -d '=' -f2`
SU=`grep "item.1.3" /tmp/aroma/gest.prop | cut -d '=' -f2`
SD=`grep "item.1.4" /tmp/aroma/gest.prop | cut -d '=' -f2`

if [ $SL = 1 ]; then
  SL=2
fi
if [ $SU == 1 ]; then
  SU=4
fi
if [ $SD == 1 ]; then
  SD=8
fi  

S2W=$(( SL + SR + SU + SD ))
echo "write /sys/android_touch/sweep2wake" $S2W >> $CONFIGFILE

#DT2W
DT2W=`grep "item.1.5" /tmp/aroma/gest.prop | cut -d '=' -f2`
echo "write /sys/android_touch/doubletap2wake" $DT2W >> $CONFIGFILE

#Shortsweep
SHORTSWEEP=`grep "item.2.1" /tmp/aroma/gest.prop | cut -d '=' -f2`
echo "write /sys/android_touch/shortsweep" $SHORTSWEEP >> $CONFIGFILE

#S2W Power key toggle
PWR_KEY=`grep "item.2.2" /tmp/aroma/gest.prop | cut -d '=' -f2`
echo "write /sys/android_touch/pwrkey_suspend" $PWR_KEY >> $CONFIGFILE

#S2W Magnetic cover toggle
LID_SUS=`grep "item.2.3" /tmp/aroma/gest.prop | cut -d '=' -f2`
echo "write /sys/android_touch/lid_suspend" $LID_SUS >> $CONFIGFILE

#S2W/DT2W Timeout
if [ ! -e /tmp/aroma/timeout.prop ]; then
  touch /tmp/aroma/timeout.prop;
fi
TIMEOUT=`cat /tmp/aroma/timeout.prop | cut -d '=' -f2`
echo "write /sys/android_touch/wake_timeout " $TIMEOUT >> $CONFIGFILE

#S2S
S2S=`grep "item.1.1" /tmp/aroma/s2s.prop | cut -d '=' -f2`
echo "write /sys/android_touch/sweep2sleep " $S2S >> $CONFIGFILE

#S2S Options
PORTRAIT=`grep "item.2.1" /tmp/aroma/s2s.prop | cut -d '=' -f2`
LANDSCAPE=`grep "item.2.2" /tmp/aroma/s2s.prop | cut -d '=' -f2`
if [ $PORTRAIT = 1 ]; then
  echo "write /sys/android_touch/orientation 1" >> $CONFIGFILE
elif [ $LANDSCAPE = 1 ]; then
  echo "write /sys/android_touch/orientation 2" >> $CONFIGFILE
else
  echo "write /sys/android_touch/orientation 0" >> $CONFIGFILE
fi

#MC Power Savings
MC_POWERSAVE=`grep "item.0.6" /tmp/aroma/misc.prop | cut -d '=' -f2`
echo -e "\n\n##### MC Power savings Settings #####\n# 0 to disable MC power savings" >> $BACKUP
echo -e "# 1 to enable maximum MC power savings\n" >> $BACKUP
if [ "$MC_POWERSAVE" = 1 ]; then
  echo "write /sys/devices/system/cpu/sched_mc_power_savings 2" >> $CONFIGFILE;
  echo "MC_POWERSAVE=1" >> $BACKUP
else
  echo "write /sys/devices/system/cpu/sched_mc_power_savings 0" >> $CONFIGFILE;
  echo "MC_POWERSAVE=0" >> $BACKUP
fi

#Fast Charge
FAST_CHARGE=`grep "item.0.1" /tmp/aroma/misc.prop | cut -d '=' -f2`
echo -e "\n\n##### Force fast-charge Settings #####\n# 0 to disable fast-charge" >> $BACKUP
echo -e "# 1 to enable fast-charge\n" >> $BACKUP
if [ $FAST_CHARGE = 1 ]; then
echo "write /sys/kernel/fast_charge/force_fast_charge 1" >> $CONFIGFILE;
echo "FAST_CHARGE=1" >> $BACKUP;
else
echo "write /sys/kernel/fast_charge/force_fast_charge 0" >> $CONFIGFILE;
echo "FAST_CHARGE=0" >> $BACKUP;
fi

#Magnetic on/off
LID=`grep "item.0.2" /tmp/aroma/misc.prop | cut -d '=' -f2`
echo -e "\n\n##### Magnetic on/off Settings #####\n# 0 to disable Magnetic on/off" >> $BACKUP
echo -e "# 1 to enable Magnetic on/off\n" >> $BACKUP
if [ $LID = 1 ]; then
echo "write /sys/module/lid/parameters/enable_lid 1" >> $CONFIGFILE
echo "LID=1" >> $BACKUP;
else
echo "write /sys/module/lid/parameters/enable_lid 0" >> $CONFIGFILE
echo "LID=0" >> $BACKUP;
fi

#USB Host mode charging
OTGCM=`grep "item.0.3" /tmp/aroma/misc.prop | cut -d '=' -f2`
echo -e "\n\n##### USB OTG+Charge Settings ######\n# 1 to enable USB host mode charging\n# 0 to disable USB host mode charging\n" >> $BACKUP
if [ $OTGCM = 1 ]; then
echo "write /sys/module/msm_otg/parameters/usbhost_charge_mode 1" >> $CONFIGFILE
echo "OTGCM=1" >> $BACKUP;
else
echo "write /sys/module/msm_otg/parameters/usbhost_charge_mode 0" >> $CONFIGFILE
echo "OTGCM=0" >> $BACKUP;
fi

#Battery life extender
BLE=`grep selected.2 /tmp/aroma/nrg.prop | cut -d '=' -f2`
echo -e "\n\n##### Battery life eXtender #####\n# 1 4.3V (stock - 100%)" >> $BACKUP
echo -e "# 2 4.2V (balanced - 93%)\n# 3 4.1V (conservative - 83%)\n# 4 4.0V (very conservative - 73%)\n" >> $BACKUP
if [ "$BLE" = 2 ]; then
  echo "write /sys/devices/i2c-0/0-006a/float_voltage 4200" >> $CONFIGFILE;
  echo "BLE=2" >> $BACKUP
elif [ "$BLE" = 3 ]; then
  echo "write /sys/devices/i2c-0/0-006a/float_voltage 4100" >> $CONFIGFILE;
  echo "BLE=3" >> $BACKUP
elif [ "$BLE" = 4 ]; then
  echo "write /sys/devices/i2c-0/0-006a/float_voltage 4000" >> $CONFIGFILE;
  echo "BLE=4" >> $BACKUP
else
  echo "write /sys/devices/i2c-0/0-006a/float_voltage 4300" >> $CONFIGFILE;
  echo "BLE=10" >> $BACKUP
fi

#fsync
#FSYNC=`grep "item.0.5" /tmp/aroma/mods.prop | cut -d '=' -f2`
#if [ $FSYNC = 1 ]; then
#  echo "write /sys/module/sync/parameters/fsync_enabled 0" >> $CONFIGFILE
#else
  echo "write /sys/module/sync/parameters/fsync_enabled 1" >> $CONFIGFILE
#fi

#Backlight dimmer
BLD=`grep "item.0.4" /tmp/aroma/misc.prop | cut -d '=' -f2`
echo -e "\n\n##### Backlight Dimmer Settings ######\n# Adjust screen brightness. A value of 4 is default, higher values decrease brightness.\n" >> $BACKUP
if [ $BLD = 1 ]; then
  echo "write /sys/module/msm_fb/parameters/backlight_dimmer 4" >> $CONFIGFILE
  echo "BLD=4" >> $BACKUP
else
  echo "write /sys/module/msm_fb/parameters/backlight_dimmer 0" >> $CONFIGFILE
  echo "BLD=0" >> $BACKUP
fi

#Max CPU_FREQ
if [ -f "/tmp/aroma/freq0.prop" ];
then
MAXF_CPU0=`cat /tmp/aroma/freq0.prop | cut -d '=' -f2`
if [ "$MAXF_CPU0" = 2 ]; then
  echo "write /sys/kernel/msm_limiter/resume_max_freq 1620000" >> $CONFIGFILE;
elif [ "$MAXF_CPU0" = 3 ]; then
  echo "write /sys/kernel/msm_limiter/resume_max_freq 1728000" >> $CONFIGFILE;
elif [ "$MAXF_CPU0" = 4 ]; then
  echo "write /sys/kernel/msm_limiter/resume_max_freq 1836000" >> $CONFIGFILE;
elif [ "$MAXF_CPU0" = 5 ]; then
  echo "write /sys/kernel/msm_limiter/resume_max_freq 1890000" >> $CONFIGFILE;
elif [ "$MAXF_CPU0" = 6 ]; then
  echo "write /sys/kernel/msm_limiter/resume_max_freq 1944000" >> $CONFIGFILE;
elif [ "$MAXF_CPU0" = 7 ]; then
  echo "write /sys/kernel/msm_limiter/resume_max_freq 1998000" >> $CONFIGFILE;
elif [ "$MAXF_CPU0" = 8 ]; then
  echo "write /sys/kernel/msm_limiter/resume_max_freq 2052000" >> $CONFIGFILE;
elif [ "$MAXF_CPU0" = 9 ]; then
  echo "write /sys/kernel/msm_limiter/resume_max_freq 2106000" >> $CONFIGFILE;
elif [ "$MAXF_CPU0" = 10 ]; then
  echo "write /sys/kernel/msm_limiter/resume_max_freq 2160000" >> $CONFIGFILE;
elif [ "$MAXF_CPU0" = 11 ]; then
  echo "write /sys/kernel/msm_limiter/resume_max_freq 2214000" >> $CONFIGFILE;
elif [ "$MAXF_CPU0" = 12 ]; then
  echo "write /sys/kernel/msm_limiter/resume_max_freq 2268000" >> $CONFIGFILE;
elif [ "$MAXF_CPU0" = 13 ]; then
  echo "write /sys/kernel/msm_limiter/resume_max_freq 2322000" >> $CONFIGFILE;
else
  echo "write /sys/kernel/msm_limiter/resume_max_freq 1512000" >> $CONFIGFILE;
fi
else
echo "write /sys/kernel/msm_limiter/resume_max_freq 1512000" >> $CONFIGFILE;
fi

#MINFREQ
if [ -f "/tmp/aroma/cpu.prop" ];
then
MINF=`grep selected.4 /tmp/aroma/cpu.prop | cut -d '=' -f2`
if [ "$MINF" = 1 ]; then
  echo "write /sys/kernel/msm_limiter/suspend_min_freq 81000" >> $CONFIGFILE;
elif [ "$MINF" = 2 ]; then
  echo "write /sys/kernel/msm_limiter/suspend_min_freq 162000" >> $CONFIGFILE;
elif [ "$MINF" = 3 ]; then
  echo "write /sys/kernel/msm_limiter/suspend_min_freq 270000" >> $CONFIGFILE;
elif [ "$MINF" = 5 ]; then
  echo "write /sys/kernel/msm_limiter/suspend_min_freq 595000" >> $CONFIGFILE;
elif [ "$MINF" = 6 ]; then
  echo "write /sys/kernel/msm_limiter/suspend_min_freq 810000" >> $CONFIGFILE;
else
  echo "write /sys/kernel/msm_limiter/suspend_min_freq 384000" >> $CONFIGFILE;
fi
else
echo "write /sys/kernel/msm_limiter/suspend_min_freq 384000" >> $CONFIGFILE;
fi

#Max suspend CPU_FREQ
if [ -f "/tmp/aroma/maxscroff.prop" ];
then
SCROFF=`cat /tmp/aroma/maxscroff.prop | cut -d '=' -f2`
if [ "`grep SCROFF=1 $KERNEL_CONF`" ]; then
  echo "write /sys/kernel/msm_limiter/suspend_max_freq 594000" >> $CONFIGFILE;
elif [ "`grep SCROFF=2 $KERNEL_CONF`" ]; then
  echo "write /sys/kernel/msm_limiter/suspend_max_freq 702000" >> $CONFIGFILE;
elif [ "`grep SCROFF=3 $KERNEL_CONF`" ]; then
  echo "write /sys/kernel/msm_limiter/suspend_max_freq 810000" >> $CONFIGFILE;
elif [ "`grep SCROFF=4 $KERNEL_CONF`" ]; then
  echo "write /sys/kernel/msm_limiter/suspend_max_freq 1026000" >> $CONFIGFILE;
elif [ "`grep SCROFF=5 $KERNEL_CONF`" ]; then
  echo "write /sys/kernel/msm_limiter/suspend_max_freq 1242000" >> $CONFIGFILE;
else
  echo "write /sys/kernel/msm_limiter/suspend_max_freq 1512000" >> $CONFIGFILE;
fi
else
echo "write /sys/kernel/msm_limiter/suspend_max_freq 1512000" >> $CONFIGFILE;
fi

#Graphics Boost
GBOOST=`grep "item.0.8" /tmp/aroma/mods.prop | cut -d '=' -f2`
if [ $GBOOST = 1 ]; then
  echo "write /sys/devices/system/cpu/cpufreq/elementalx/gboost 0" >> $CONFIGFILE
fi

#THERMAL
THERM=`grep selected.1 /tmp/aroma/nrg.prop | cut -d '=' -f2`
echo -e "\n\n##### Thermal Settings #####\n# 0 for default thermal throttling" >> $BACKUP
echo -e "# 1 to run cool\n# 2 to run hot\n" >> $BACKUP
if [ "$THERM" = 1 ]; then
  echo "write /sys/module/msm_thermal/parameters/limit_temp_degC 65" >> $CONFIGFILE;
  echo "write /sys/module/msm_thermal/parameters/core_limit_temp_degC; 75" >> $CONFIGFILE;
  echo "write /sys/module/msm_thermal/parameters/freq_control_mask 14" >> $CONFIGFILE;
  echo "write /sys/module/msm_thermal/parameters/core_control_mask 12" >> $CONFIGFILE;
  echo "THERM=1" >> $BACKUP
elif [ "$THERM" = 3 ]; then
  echo "write /sys/module/msm_thermal/parameters/limit_temp_degC 80" >> $CONFIGFILE;
  echo "write /sys/module/msm_thermal/parameters/core_limit_temp_degC; 90" >> $CONFIGFILE;
  echo "write /sys/module/msm_thermal/parameters/freq_control_mask 14" >> $CONFIGFILE;
  echo "write /sys/module/msm_thermal/parameters/core_control_mask 12" >> $CONFIGFILE;
  echo "THERM=3" >> $BACKUP
else
  echo "write /sys/module/msm_thermal/parameters/limit_temp_degC 70" >> $CONFIGFILE;
  echo "write /sys/module/msm_thermal/parameters/core_limit_temp_degC; 80" >> $CONFIGFILE;
  echo "write /sys/module/msm_thermal/parameters/freq_control_mask 14" >> $CONFIGFILE;
  echo "write /sys/module/msm_thermal/parameters/core_control_mask 12" >> $CONFIGFILE;
  echo "THERM=2" >> $BACKUP
fi

#HOTPLUGDRV
HOTPLUGDRV=`grep selected.2 /tmp/aroma/cpu.prop | cut -d '=' -f2`
if [ "$HOTPLUGDRV" = 1 ]; then
  echo "write /sys/module/msm_mpdecision/parameters/enabled 0" >> $CONFIGFILE;
  echo "write /sys/module/msm_hotplug/msm_enabled 1" >> $CONFIGFILE;
  echo "write /sys/module/intelli_plug/parameters/intelli_plug_active 0" >> $CONFIGFILE;
  echo "write /sys/module/intelli_plug/parameters/touch_boost_active 0" >> $CONFIGFILE;
  echo "write /sys/module/lazyplug/parameters/lazyplug_active 0" >> $CONFIGFILE;
elif [ "$HOTPLUGDRV" = 2 ]; then
  echo "write /sys/module/msm_mpdecision/parameters/enabled 0" >> $CONFIGFILE;
  echo "write /sys/module/msm_hotplug/msm_enabled 0" >> $CONFIGFILE;
  echo "write /sys/module/intelli_plug/parameters/intelli_plug_active 1" >> $CONFIGFILE;
  echo "write /sys/module/intelli_plug/parameters/touch_boost_active 1" >> $CONFIGFILE;
  echo "write /sys/module/lazyplug/parameters/lazyplug_active 0" >> $CONFIGFILE;
elif [ "$HOTPLUGDRV" = 3 ]; then
  echo "write /sys/module/msm_mpdecision/parameters/enabled 0" >> $CONFIGFILE;
  echo "write /sys/module/msm_hotplug/msm_enabled 0" >> $CONFIGFILE;
  echo "write /sys/module/intelli_plug/parameters/intelli_plug_active 0" >> $CONFIGFILE;
  echo "write /sys/module/intelli_plug/parameters/touch_boost_active 0" >> $CONFIGFILE;
  echo "write /sys/module/lazyplug/parameters/lazyplug_active 1" >> $CONFIGFILE;
else
  echo "write /sys/module/msm_mpdecision/parameters/enabled 1" >> $CONFIGFILE;
  echo "write /sys/module/msm_hotplug/msm_enabled 0" >> $CONFIGFILE;
  echo "write /sys/module/intelli_plug/parameters/intelli_plug_active 0" >> $CONFIGFILE;
  echo "write /sys/module/intelli_plug/parameters/touch_boost_active 0" >> $CONFIGFILE;
  echo "write /sys/module/lazyplug/parameters/lazyplug_active 0" >> $CONFIGFILE;
fi

#GPU Governor
GPU_GOV=`grep selected.2 /tmp/aroma/gpu.prop | cut -d '=' -f2`
if [ $GPU_GOV = 2 ]; then
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/pwrscale/trustzone/governor simple" >> $CONFIGFILE
fi

echo "" >> $CONFIGFILE
echo "on property:sys.boot_completed=1" >> $CONFIGFILE
echo "" >> $CONFIGFILE

#I/O scheduler
IOSCHED=`grep selected.1 /tmp/aroma/disk.prop | cut -d '=' -f2`
if [ $IOSCHED = 1 ]; then
  echo "write /sys/block/mmcblk0/queue/scheduler cfq" >> $CONFIGFILE
elif [ $IOSCHED = 2 ]; then
  echo "write /sys/block/mmcblk0/queue/scheduler row" >> $CONFIGFILE
elif [ $IOSCHED = 3 ]; then
  echo "write /sys/block/mmcblk0/queue/scheduler deadline" >> $CONFIGFILE
elif [ $IOSCHED = 4 ]; then
  echo "write /sys/block/mmcblk0/queue/scheduler fiops" >> $CONFIGFILE
elif [ $IOSCHED = 5 ]; then
  echo "write /sys/block/mmcblk0/queue/scheduler sio" >> $CONFIGFILE
elif [ $IOSCHED = 6 ]; then
  echo "write /sys/block/mmcblk0/queue/scheduler noop" >> $CONFIGFILE
elif [ $IOSCHED = 7 ]; then
  echo "write /sys/block/mmcblk0/queue/scheduler bfq" >> $CONFIGFILE
elif [ $SCHED = 8 ]; then
  echo "write /sys/block/mmcblk0/queue/scheduler zen" >> $CONFIGFILE
fi

#read-ahead
READAHEAD=`grep selected.2 /tmp/aroma/disk.prop | cut -d '=' -f2`
if [ $READAHEAD = 1 ]; then
  echo "write /sys/block/mmcblk0/queue/read_ahead_kb 128" >> $CONFIGFILE
elif [ $READAHEAD = 2 ]; then
  echo "write /sys/block/mmcblk0/queue/read_ahead_kb 256" >> $CONFIGFILE
elif [ $READAHEAD = 3 ]; then
  echo "write /sys/block/mmcblk0/queue/read_ahead_kb 512" >> $CONFIGFILE
elif [ $READAHEAD = 4 ]; then
  echo "write /sys/block/mmcblk0/queue/read_ahead_kb 1024" >> $CONFIGFILE
elif [ $READAHEAD = 5 ]; then
  echo "write /sys/block/mmcblk0/queue/read_ahead_kb 2048" >> $CONFIGFILE
elif [ $READAHEAD = 6 ]; then
  echo "write /sys/block/mmcblk0/queue/read_ahead_kb 4096" >> $CONFIGFILE
else
echo "write /sys/block/mmcblk0/queue/read_ahead_kb 128" >> $CONFIGFILE
fi
echo "" >> $CONFIGFILE

#GPU Clock
GPU_OC=`grep selected.1 /tmp/aroma/gpu.prop | cut -d '=' -f2`
if [ $GPU_OC = 1 ]; then
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/max_gpuclk 320000000" >> $CONFIGFILE
elif [ $GPU_OC = 2 ]; then
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/max_gpuclk 400000000" >> $CONFIGFILE
elif [ $GPU_OC = 3 ]; then
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/max_gpuclk 450000000" >> $CONFIGFILE
elif [ $GPU_OC = 4 ]; then
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/max_gpuclk 504000000" >> $CONFIGFILE
elif [ $GPU_OC = 5 ]; then
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/max_gpuclk 545000000" >> $CONFIGFILE
elif [ $GPU_OC = 6 ]; then
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/max_gpuclk 600000000" >> $CONFIGFILE
elif [ $GPU_OC = 7 ]; then
  echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/max_gpuclk 627000000" >> $CONFIGFILE
else
echo "write /sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/max_gpuclk 450000000" >> $CONFIGFILE
fi

#GPU UV
GPU_UV=`grep selected.4 /tmp/aroma/nrg.prop | cut -d '=' -f2`
if [ "$GPU_UV" = 2 ]; then
  echo "write /sys/devices/system/cpu/cpufreq/vdd_table/vdd_levels_GPU \"920000\n1025000\n1125000\n\"" >> $CONFIGFILE;
elif [ "$GPU_UV" = 3 ]; then
  echo "write /sys/devices/system/cpu/cpufreq/vdd_table/vdd_levels_GPU \"900000\n1000000\n1100000\n\"" >> $CONFIGFILE;
elif [ "$GPU_UV" = 4 ]; then
  echo "write /sys/devices/system/cpu/cpufreq/vdd_table/vdd_levels_GPU \"900000\n975000\n1075000\n\"" >> $CONFIGFILE;
elif [ "$GPU_UV" = 5 ]; then
  echo "write /sys/devices/system/cpu/cpufreq/vdd_table/vdd_levels_GPU \"900000\n950000\n1050000\n\"" >> $CONFIGFILE;
elif [ "$GPU_UV" = 6 ]; then
  echo "write /sys/devices/system/cpu/cpufreq/vdd_table/vdd_levels_GPU \"900000\n925000\n1025000\n\"" >> $CONFIGFILE;
elif [ "$GPU_UV" = 7 ]; then
  echo "write /sys/devices/system/cpu/cpufreq/vdd_table/vdd_levels_GPU \"900000\n900000\n1000000\n\"" >> $CONFIGFILE;
else
  echo "write /sys/devices/system/cpu/cpufreq/vdd_table/vdd_levels_GPU \"945000\n1050000\n1150000\n\"" >> $CONFIGFILE;
fi

#CPU governor
CPU_GOV=`grep selected.3 /tmp/aroma/cpu.prop | cut -d '=' -f2`
if [ "$CPU_GOV" = 1 ]; then
  echo "write /sys/kernel/msm_limiter/scaling_governor ondemand" >> $CONFIGFILE;
elif [ "$CPU_GOV" = 2 ]; then
  echo "write /sys/kernel/msm_limiter/scaling_governor interactive" >> $CONFIGFILE;
elif [ "$CPU_GOV" = 3 ]; then
  echo "write /sys/kernel/msm_limiter/scaling_governor intellidemand" >> $CONFIGFILE;
elif [ "$CPU_GOV" = 4 ]; then
  echo "write /sys/kernel/msm_limiter/scaling_governor smartmax" >> $CONFIGFILE;
elif [ "$CPU_GOV" = 5 ]; then
  echo "write /sys/kernel/msm_limiter/scaling_governor smartmax_eps" >> $CONFIGFILE;
elif [ "$CPU_GOV" = 6 ]; then
  echo "write /sys/kernel/msm_limiter/scaling_governor intelliactive" >> $CONFIGFILE;
elif [ "$CPU_GOV" = 7 ]; then
  echo "write /sys/kernel/msm_limiter/scaling_governor conservative" >> $CONFIGFILE;
else
  echo "write /sys/kernel/msm_limiter/scaling_governor interactive" >> $CONFIGFILE;
fi

#RESTORE
echo -e "\n\n\n## RESTORE ##" > $BACKUP

#UV
UV_LEVEL=$(grep selected.3 /tmp/aroma/nrg.prop | cut -d '=' -f2)
echo -e "\n\n##### Level of uV to apply to low frequencies (equal to or lower than 384MHz)#####" >> $BACKUP
echo -e "# 0 stock(no uV)\n# 1 -50 mV\n# 2 -75 mV\n# 3 -100 mV\n# 4 -125 mV" >> $BACKUP
echo -e "# 5 -150 mV\n# 6 -175 mV\n" >> $BACKUP
if [ "$UV_LEVEL" = 2 ]; then
  echo "UV_LEVEL=1" >> $BACKUP;
elif [ "$UV_LEVEL" = 3 ]; then
  echo "UV_LEVEL=2" >> $BACKUP;
elif [ "$UV_LEVEL" = 4 ]; then
  echo "UV_LEVEL=3" >> $BACKUP;
elif [ "$UV_LEVEL" = 5 ]; then
  echo "UV_LEVEL=4" >> $BACKUP;
elif [ "$UV_LEVEL" = 6 ]; then
  echo "UV_LEVEL=5" >> $BACKUP;
elif [ "$UV_LEVEL" = 7 ]; then
  echo "UV_LEVEL=6" >> $BACKUP;
else
  echo "UV_LEVEL=0" >> $BACKUP;
fi

#L2/CACHE OC
L2_OC=$(grep selected.1 /tmp/aroma/cpu.prop | cut -d '=' -f2)
echo -e "\n\n##### L2/cache OC settings #####\n# 0 stock(1.13GHz-4.26GBps)\n# 1 improved(1.19GHz-4.26GBps)" >> $BACKUP
echo -e "# 2 balanced(1.22GHz-4.66GBps)\n# 3 fast(1.35GHz-4.66GBps)\n# 4 extreme(1.43GHz-4.80GBps)" >> $BACKUP
echo -e "# 5 glitchy(1.49GHz-4.96GBps)\n" >> $CONFIGFILE
if [ "$L2_OC" = 2 ]; then
  echo "L2_OC=1" >> $BACKUP;
elif [ "$L2_OC" = 3 ]; then
  echo "L2_OC=2" >> $BACKUP;
elif [ "$L2_OC" = 4 ]; then
  echo "L2_OC=3" >> $BACKUP;
elif [ "$L2_OC" = 5 ]; then
  echo "L2_OC=4" >> $BACKUP;
elif [ "$L2_OC" = 6 ]; then
  echo "L2_OC=5" >> $BACKUP;
else
  echo "L2_OC=0" >> $BACKUP;
fi


echo -e "\n\n##############################" >> $BACKUP
#END
