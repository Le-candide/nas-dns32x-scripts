#!/bin/sh
#======================================================================================================================
# Patch /bin/chmod to prevent execution of the command: "chmod -R 777 /mnt/USB/mount_dir" or "chmod -R 777 /mnt/HD/mount_dir" 
# Execute this script under FFP (use telnet or ssh)
# Source : http://forum.dsmg600.info/viewtopic.php?id=6194
#----------------------------------------------------------------------------------------------------------------------
# Usage: patch_chmod.sh [on|off]
#   on  : install the patch
#   off : uninstall the patch
#----------------------------------------------------------------------------------------------------------------------
# Adapted by le_candide : 27/01/2015 23/04/2012
#======================================================================================================================

#======================================================================================================================
# 1- inits
#======================================================================================================================
PATH=/sbin:/usr/sbin:/bin:/usr/bin
PATCHED_CHMOD=/usr/local/config/chmod_usb.sh
LOG_FILE=/usr/local/config/chmod.log
MTD_CHECK_FILE=/usr/sbin/mtd_check


#======================================================================================================================
# 2- functions
#======================================================================================================================
p_install () {
#----------------------------------------------------------------------------------------------------------------------
cat <<EOF >$PATCHED_CHMOD
#!/bin/sh
# This script replaces the chmod to disable "chmod 777" on mounted drive
PATH=/sbin:/usr/sbin:/bin:/usr/bin
if echo "\$@"|grep 777|egrep -q "/mnt/(USB|HD)/[a-zA-Z0-9_]*$" ; then
   echo "[\`date +'%Y-%m-%d %T'\`] ## Disabling ## chmod \$@">> $LOG_FILE
else
   echo "[\`date +'%Y-%m-%d %T'\`]    Executing    chmod \$@">> $LOG_FILE
   /bin/busybox chmod \$@
fi

EOF
chmod 777 $PATCHED_CHMOD
printf "# chmod trace :\n\n">$LOG_FILE
chmod a+rw $LOG_FILE

# modify the link to chmod
[ -x $PATCHED_CHMOD ] && ln -nfs $PATCHED_CHMOD /bin/chmod

# Remove older installations in rc.init.sh file
sed -i '/^### UWCHMOD BEGIN ###/,/^### UWCHMOD END ###/d; /chmod_usb.sh/d; /^# Pach chmod/d' /usr/local/config/rc.init.sh 

# link chmod to the patched_chmod in mtd_check file
rm -f $MTD_CHECK_FILE
cat <<EOF >$MTD_CHECK_FILE
#!/bin/sh
[ -x $PATCHED_CHMOD ] && ln -nfs $PATCHED_CHMOD /bin/chmod
/usr/local/modules/usrsbin/mtd_check
EOF
/ffp/bin/chattr +i  $MTD_CHECK_FILE
chmod 777 $MTD_CHECK_FILE
echo "The patch is installed."
}

p_uninstall () {
#----------------------------------------------------------------------------------------------------------------------
# Restore rc.init.sh file
ln -nfs /usr/local/modules/usrsbin/mtd_check $MTD_CHECK_FILE
rm -f $LOG_FILE $PATCHED_CHMOD

# Restore link for /bin/chmod
ln -snf busybox /bin/chmod
echo "The patch is uninstalled."
}


#======================================================================================================================
# 3- main
#======================================================================================================================
if echo "$1"|egrep -qiw "on"; then
   p_install
elif echo "$1"|egrep -qiw "off"; then
   p_uninstall
else
   # Usage (syntax error)
   printf "Usage: patch_chmod.sh [on|off]\n   on  : install the patch\n   off : uninstall the patch\n\n"
fi


