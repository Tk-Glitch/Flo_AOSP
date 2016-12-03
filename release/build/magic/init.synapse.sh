#!/system/xbin/busybox sh

wait ${!}

# Mount root as RW to apply tweaks and settings
mount -o remount,rw /;
mount -o rw,remount /system

# allow untrusted apps to read from debugfs
/system/xbin/supolicy --live \
	"allow untrusted_app debugfs file { open read getattr }" \
	"allow untrusted_app sysfs_hardware file { open read getattr }" \
	"allow untrusted_app sysfs_lowmemorykiller file { open read getattr }" \
	"allow untrusted_app persist_file dir { open read getattr }" \
	"allow debuggerd gpu_device chr_file { open read getattr }" \
	"allow netd netd capability fsetid" \
	"allow netd { hostapd dnsmasq } process fork" \
	"allow { system_app shell } dalvikcache_data_file file write" \
	"allow { zygote mediaserver bootanim appdomain }  theme_data_file dir { search r_file_perms r_dir_perms }" \
	"allow { zygote mediaserver bootanim appdomain }  theme_data_file file { r_file_perms r_dir_perms }" \
	"allow system_server { rootfs resourcecache_data_file } dir { open read write getattr add_name setattr create remove_name rmdir unlink link }" \
	"allow system_server resourcecache_data_file file { open read write getattr add_name setattr create remove_name unlink link }" \
	"allow system_server dex2oat_exec file rx_file_perms" \
	"allow mediaserver mediaserver_tmpfs file execute" \
	"allow drmserver theme_data_file file r_file_perms"

# Make tmp folder
mkdir /tmp;

# Give permissions to execute
chown -R root:system /tmp/;
chmod -R 777 /tmp/;
chmod -R 777 /res/;
chmod 6755 /data/synapse/actions/*;
chmod 6755 /sbin/*;
chmod 6755 /system/xbin/*;
echo "Boot initiated on $(date)" > /tmp/bootcheck;

ln -s /data/synapse/uci /system/xbin/uci
/system/xbin/uci

# Init.d Support
/system/xbin/busybox run-parts /system/etc/init.d

exit;
