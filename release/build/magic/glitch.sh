# Restart GMS on boot to fix memory leak and power drain
if [ "$(pidof com.google.android.gms | wc -l)" -eq "1" ]; then
	kill $(pidof com.google.android.gms);
fi;
if [ "$(pidof com.google.android.gms.unstable | wc -l)" -eq "1" ]; then
	kill $(pidof com.google.android.gms.unstable);
fi;
if [ "$(pidof com.google.android.gms.persistent | wc -l)" -eq "1" ]; then
	kill $(pidof com.google.android.gms.persistent);
fi;
if [ "$(pidof com.google.android.gms.wearable | wc -l)" -eq "1" ]; then
	kill $(pidof com.google.android.gms.wearable);
fi;

exit;