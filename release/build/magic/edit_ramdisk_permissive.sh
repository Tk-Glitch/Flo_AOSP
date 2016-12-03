#!/sbin/sh

mkdir /tmp/ramdisk
cp /tmp/initrd.img /tmp/ramdisk/initrd.gz
cd /tmp/ramdisk/
gunzip -c /tmp/ramdisk/initrd.gz | cpio -i
rm /tmp/ramdisk/initrd.gz
rm /tmp/initrd.img

#Start glitch script
if [ -f "/tmp/ramdisk/init.rc" ]; then
if [ $(grep -c "import /init.glitch.rc" /tmp/ramdisk/init.rc) == 0 ]; then
   sed -i "/import \/init\.environ\.rc/aimport /init.glitch.rc" /tmp/ramdisk/init.rc
fi
fi

if [ -f "/tmp/ramdisk/init.elementalx.rc" ]; then
rm /tmp/ramdisk/init.elementalx.rc
fi

#disable selinux enforcing
if [ $(grep -c "setenforce 0" /tmp/ramdisk/init.rc) == 0 ] && [ $(grep -c "setenforce 1" /tmp/ramdisk/init.rc) == 0 ]; then
   sed -i "s/setcon u:r:init:s0/setcon u:r:init:s0\n    setenforce 0/" /tmp/ramdisk/init.rc
else
if [ $(grep -c "setenforce 1" /tmp/ramdisk/init.rc) == 1 ]; then
   sed -i "s/setenforce 1/setenforce 0/" /tmp/ramdisk/init.rc
fi
fi

#enable selinux enforcing
#if [ $(grep -c "setenforce 0" /tmp/ramdisk/init.rc) == 0 ] && [ $(grep -c "setenforce 1" /tmp/ramdisk/init.rc) == 0 ]; then
#   sed -i "s/setcon u:r:init:s0/setcon u:r:init:s0\n    setenforce 1/" /tmp/ramdisk/init.rc
#else
#if [ $(grep -c "setenforce 0" /tmp/ramdisk/init.rc) == 1 ]; then
#   sed -i "s/setenforce 0/setenforce 1/" /tmp/ramdisk/init.rc
#fi
#fi

#remove install_recovery
if [ $(grep -c "#seclabel u:r:install_recovery:s0" /tmp/ramdisk/init.rc) == 0 ] && [ $(grep -c "seclabel u:r:install_recovery:s0" /tmp/ramdisk/init.rc) == 1 ]; then
   sed -i "s/seclabel u:r:install_recovery:s0/#seclabel u:r:install_recovery:s0/" /tmp/ramdisk/init.rc
fi

#add init.d support if needed
if [ !$(grep -qr "init.d" /tmp/ramdisk/*) ]; then
   echo "" >> /tmp/ramdisk/init.rc
   echo "service userinit /system/sbin/busybox run-parts /system/etc/init.d" >> /tmp/ramdisk/init.rc
   echo "    oneshot" >> /tmp/ramdisk/init.rc
   echo "    class late_start" >> /tmp/ramdisk/init.rc
   echo "    user root" >> /tmp/ramdisk/init.rc
   echo "    group root" >> /tmp/ramdisk/init.rc
fi

#remove governor overrides, use kernel default
sed -i '/\/sys\/devices\/system\/cpu\/cpu0\/cpufreq\/scaling_governor/d' /tmp/ramdisk/init.flo.rc
sed -i '/\/sys\/devices\/system\/cpu\/cpu1\/cpufreq\/scaling_governor/d' /tmp/ramdisk/init.flo.rc
sed -i '/\/sys\/devices\/system\/cpu\/cpu2\/cpufreq\/scaling_governor/d' /tmp/ramdisk/init.flo.rc
sed -i '/\/sys\/devices\/system\/cpu\/cpu3\/cpufreq\/scaling_governor/d' /tmp/ramdisk/init.flo.rc

#restore fstab backup
if [ -f "/tmp/ramdisk/fstab.orig" ]; then
rm /tmp/ramdisk/fstab.flo
mv /tmp/ramdisk/fstab.orig /tmp/ramdisk/fstab.flo
fi

#backup fstab
cp /tmp/ramdisk/fstab.flo /tmp/ramdisk/fstab.orig

#Check for F2FS and change fstab accordingly in ramdisk except for cm or if F2FS is found in the original fstab

if [ ! -f "/tmp/ramdisk/init.cm.rc" ] || [ $(grep -c "f2fs" /tmp/ramdisk/fstab.flo) == 0 ]; then

mount /cache 2> /dev/null
mount /data 2> /dev/null
mount /system 2> /dev/null

mount | grep -q 'cache type f2fs'
CACHE_F2FS=$?
mount | grep -q 'data type f2fs'
DATA_F2FS=$?
mount | grep -q 'system type f2fs'
SYSTEM_F2FS=$?

#System partition
if [ $SYSTEM_F2FS -eq 0 ]; then
sed -i 's/.*by-name\/system.*/\/dev\/block\/platform\/msm_sdcc.1\/by-name\/system       \/system         f2fs    ro,nosuid,nodev,noatime,nodiratime,inline_xattr                              wait/g' /tmp/ramdisk/fstab.flo
else
sed -i 's/.*by-name\/system.*/\/dev\/block\/platform\/msm_sdcc.1\/by-name\/system       \/system         ext4    ro,barrier=1                                                                 wait/g' /tmp/ramdisk/fstab.flo
fi

#Cache partition
if [ $CACHE_F2FS -eq 0 ]; then
sed -i 's/.*by-name\/cache.*/\/dev\/block\/platform\/msm_sdcc.1\/by-name\/cache        \/cache          f2fs    rw,nosuid,nodev,noatime,inline_xattr                              wait,check,formattable/g' /tmp/ramdisk/fstab.flo
else
sed -i 's/.*by-name\/cache.*/\/dev\/block\/platform\/msm_sdcc.1\/by-name\/cache        \/cache          ext4    noatime,nosuid,nodev,barrier=1,data=ordered,noauto_da_alloc,errors=panic     wait,check,formattable/g' /tmp/ramdisk/fstab.flo
fi

#Data partition
if [ $DATA_F2FS -eq 0 ]; then
sed -i 's/.*by-name\/userdata.*/\/dev\/block\/platform\/msm_sdcc.1\/by-name\/userdata     \/data           f2fs    rw,nosuid,nodev,noatime,inline_xattr                              wait,check,formattable,encryptable=\/dev\/block\/platform\/msm_sdcc.1\/by-name\/metadata/g' /tmp/ramdisk/fstab.flo
else
sed -i 's/.*by-name\/userdata.*/\/dev\/block\/platform\/msm_sdcc.1\/by-name\/userdata     \/data           ext4    noatime,nosuid,nodev,barrier=1,data=ordered,noauto_da_alloc,errors=panic     wait,check,formattable,encryptable=\/dev\/block\/platform\/msm_sdcc.1\/by-name\/metadata/g' /tmp/ramdisk/fstab.flo
fi

sed -i '$!N; /^\(.*\)\n\1$/!P; D' /tmp/ramdisk/fstab.flo

fi

#copy glitch scripts & bb
cp /tmp/busybox /tmp/ramdisk/sbin/busybox
chmod 755 /tmp/ramdisk/sbin/busybox
cp /tmp/glitch.sh /tmp/ramdisk/sbin/glitch.sh
chmod 755 /tmp/ramdisk/sbin/glitch.sh
cp /tmp/init.glitch.rc /tmp/ramdisk/init.glitch.rc
chmod 750 /tmp/ramdisk/init.glitch.rc

#repack
find . | cpio -o -H newc | gzip > /tmp/initrd.img
