#! /bin/sh -

# snap shot from debian i386 source August 2016

#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#
# Customisation:
#   The devices fall into various classes.  This section contains the mapping
# from a class name into a group name and permission.
#   You will almost certainly need to edit the group name to match your
# system, and you may change the permissions to suit your preference.  These
# lines _must_ be of the format "user group perm".
#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#

public="   root root   0666"
private="  root root   0600"
system="   root root   0660"
kmem="     root kmem   0640"
tty="      root tty    0666"
cons="     root tty    0600"
dialout="  root dialout 0660"
dip="      root dip    0660"
mouse="    root root   0660"
printer="  root lp     0660"
floppy="   root floppy 0660"
disk="     root disk   0660"
scsi="     root root   0600"
cdrom="    root cdrom  0660"
tape="     root tape   0660"
audio="    root audio  0660"
video="    root video  0660"
ibcs2="    root root   0666"
scanner="  root root   0666"
coda="     root root   0600"
ipsec="    root root   0200"
readable=" root root   0444"
lirc="     root video   0640"

MAXVT=63

# defaults for $major_*
major_ide0=3
major_ide1=22
major_sd=8
major_lp=6

# Remark: OSS/Linux becomes major_OSSLinux
# NON default #---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#

# for exploration and testing
testdir="test_devices"
RUNAT=$(pwd)

warning(){
    # function to warn about spontaneous device creation.
    # the intent here is as for the warning text and no more.
    # This is not a manual page
    
    cat <<EOF
#--#     WARNING $USER   #--# 
    This can get messy.

$0 will potentially create an entire device tree right here at:
$(pwd) 

Please Consider::  
move cp $0 to /dev/MAKEDEV e.g.  
    cp -vup  $0 /dev/MAKEDEV 

or 
link $0 to /dev/MAKEDEV e.g.
    ln -s /dev/MAKEDEV $0 

or 
mkdir ${testdir} (which will be autodetected) 
and then place and run a $0 there.
(and THEN say Yes :)
$USER needs to run $0 with root level permissions.
e.g. $0 netlink  || default-i386 || tty 


EOF
 
read  -p"Proceed locally [ Yes or No] : "  AFFIRM  

case $AFFIRM in
    Yes | yes | affirm* | Y | y)
	echo "OK Proceeding with $@ run"
	echo "do check for possible dot directories"
        sleep 1
	# get out the way there is potentially a lot to > here
	clear
	export noloops=seen
	;;
    No | n | N | no | nup | stop | halt | bail)
	echo "Avoiding a potential mess"
	echo "Probably a wise move"
	exit 0
	;;
    *)
	clear
	echo "$AFFIRM is an unforseen response"
	sleep 2
	echo "Leaving you to think about \"$AFFIRM\"." 
	exit 1
	;;
esac

return 0
}


if [ $@ ]; then
    # this script calls itself possibly many times
    # this test avoids ever hitting
    # the warning guff when called with purpose  
    echo "$0 attempting $@"
    : #true pass
elif [ $noloops ]; then
    # echo "seen this before"
    export noloops=seen 
    : #true pass
elif [ "${RUNAT}" != "/dev" ] || [ "$(basename ${RUNAT})" != "$testdir" ] ; then
    warning 
else
    noloops=seenandset 
fi

#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#
# try to do the right things if udev is running
#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#
if [ "$WRITE_ON_UDEV" ]; then
    :
elif [ -d /dev/.static/dev/ ] && [ "`pwd`" = /dev ] && [ -e /proc/mounts ] \
	 && grep -qE '^[^ ]+ /dev/\.static/dev' /proc/mounts; then
    echo "udev active, devices will be created in /dev/.static/dev/"
    cd /dev/.static/dev/
elif [ -d /.dev/ ] && [ "`pwd`" = /dev ] && [ -e /proc/mounts ] \
	 && grep -qE '^[^ ]+ /\.dev' /proc/mounts; then
    echo "udev active, devices will be created in /.dev/"
    cd /.dev/
elif [ -d /run/udev -o -d .udevdb/ -o -d .udev/ ] && [ "`pwd`" = /dev ]; then
    echo "/run/udev or .udevdb or .udev presence implies active udev.  Aborting MAKEDEV invocation."
  # use exit 0, not 1, so postinst scripts don't fail on this
  exit 0
fi

#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#
# don't stomp on devfs users
#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#
if  [ -c .devfsd ]
then
    echo ".devfsd presence implies active DevFS.  Aborting MAKEDEV invocation."
    # use exit 0, not 1, so postinst scripts don't fail on this
    exit 0
fi

#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#
# don't stomp on non-Linux users
#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#
if [ "$(uname -s)" != "Linux" ]
then
    echo "Results undefined on non-Linux systems, aborting MAKEDEV invocation."
    # use exit 0, not 1, so postinst scripts don't fail on this
    exit 0
fi

#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#

procfs=/proc

opt_v=
opt_d=
opt_n=

while [ $# -ge 1 ]
do
	case $1 in
		--)	shift; break ;;
		-v)	shift; opt_v=1 ;;
		-d)	shift; opt_d=1 ;;
		-n)	shift; opt_n=1; opt_v=1 ;;
		-V)	shift; opt_V=1 ;;
		-*)	echo "$0: unknown flag \"$1\"" >&2; exit 1 ;;
		*)	break ;;
	esac
done

if [ "$opt_V" ]
then
	echo "This was Devuan | Debian MAKEDEV."  
	echo "For version info, try 'dpkg --list makedev'"
	echo "See /usr/share/doc/makedev/ for more information on Devuan MAKEDEV."
	exit 0
fi

opts="${opt_n:+-n} ${opt_v:+-v} ${opt_d:+-d}"

#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#
#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#

devicename () {	# translate device names to something safe
	# A-Z is not full alphabet in all locales (e.g. in et_EE)
	echo "$*" | LC_ALL=C sed -e 's/[^A-Za-z0-9_]/_/g' 
}

makedev () {	# usage: makedev name [bcu] major minor owner group mode
	if [ "$opt_v" ]
	then	if [ "$opt_d" ]
		then	echo "delete $1"
		else	echo "create $1	$2 $3 $4 $5:$6 $7" 
		fi
	fi
	# missing parameters are a bug - bail - should we do an exit 1 here?
	case :$1:$2:$3:$4:$5:$6:$7: in
		*::*) echo "Warning: MAKEDEV $@ is missing parameter(s)." >&2;;
	esac
	if [ ! "$opt_n" ]
	then	
		if [ "$opt_d" ]
		then
			rm -f $1
		else
			rm -f $1-
			if mknod $1- $2 $3 $4 &&
			   chown $5:$6 $1- &&
			   chmod $7 $1- &&
			   mv $1- $1
			then
				:	# it worked
			else
					# Didn't work, clean up any mess...
				echo "makedev $@: failed"
				rm -f $1-
			fi
		fi
	fi
}
makefifo () { # usage: makefifo name owner group mode
	if [ "$opt_v" ]
	then	if [ "$opt_d" ]
		then	echo "delete $1"
		else	echo "create $1 $2:$3 $4" 
		fi
	fi
	# missing parameters are a bug - bail - should we do an exit 1 here?
	case :$1:$2:$3:$4: in
		*::*) echo "Warning: MAKEFIFO $@ is missing parameter(s)." >&2;;
	esac
	if [ ! "$opt_n" ]
	then	
		if [ "$opt_d" ]
		then
			rm -f $1
		else
			rm -f $1-
			if mknod $1- p &&
			   chown $2:$3 $1- &&
			   chmod $4 $1- &&
			   mv $1- $1
			then
				:	# it worked
			else
					# Didn't work, clean up any mess...
				echo "makefifo $@: failed"
				rm -f $1-
			fi
		fi
	fi
}
symlink () {	# usage: symlink name target
	if [ "$opt_v" ]
	then	if [ "$opt_d" ]
		then	echo "delete $1"
		else	echo "create $1	-> $2"
		fi
	fi
	[ ! "$opt_n" ] && rm -f $1 &&
	[ ! "$opt_d" ] && ln -s $2 $1
}

#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#

# Debian allows us to assume /bin/sh is a POSIX compliant shell, so go for it!

math () {
	eval echo "\$(($*))"
}
index () {	# index string c
	eval "I=\${1%$2*}"
	eval echo "\${#I}"
}
suffix () {
	eval echo "\${1#$2}"
}
strip () {
	eval echo "\${1% $2 *} \${1#* $2 }"
}
first () {
	echo "${1%%?}"
}
second () {
	echo "${1##?}"
}
substr () {
	echo $1 | dd bs=1 count=1 skip=$(( $2 - 1 )) 2> /dev/null
}

#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#---#

devices=
if [ ! -f $procfs/devices ]
then
    echo "$0: warning: can't read $procfs/devices" >&2
else
    exec 3<$procfs/devices
    while read major device extra <&3
    do
	device=`echo $device | sed 's#/.*##'`
	case "$major" in
	    Character|Block|'')
	    ;;
	    *)
		safedevname=`devicename $device`
		eval "major_$safedevname=$major"
		devices="$devices $device"
		;;
	esac
    done
    exec 3<&-
fi

Major () {
    device=$2
    devname=`devicename $1`
    if [ "$opt_d" ]
    then
	echo -1	# don't care
    else
	eval echo \${major_$devname:-\${device:?\"unknown major number for $1\"}}
    fi
}

cvt () {
    while [ $# -ne 0 ]
    do
	case "$1" in
	    mem|tty|ttyp|cua|cub|cui)	;;
	    hd)	(for d in a b c d e f g h i j k l m n o p ; do
		     echo -n hd$d " "
		 done) ; echo
		;;
	    ide0)	echo hda hdb ;;
	    ide1)	echo hdc hdd ;;
	    ide2)	echo hde hdf ;;
	    ide3)	echo hdg hdh ;;
	    ide4)	echo hdi hdj ;;
	    ide5)	echo hdk hdl ;;
	    ide6)	echo hdm hdn ;;
	    ide7)	echo hdo hdp ;;
	    ide8)	echo hdq hdr ;;
	    ide9)	echo hds hdt ;;
	    sd)	(for d in a b c d e f g h i j k l m n o p ; do
		     echo -n sd$d " "
		 done) ; echo
		;;
	    dasd)   (for d in a b c d e f g h i j k l m \
				n o p q r s t u v w x y z ; do
			 echo -n dasd$d " "
		     done) ; echo
		    ;;
	    raw)	echo raw ;;
	    sg)	echo sg ;;
	    sr)	echo scd ;;
	    st)	echo st0 ;;
	    xd)	echo xda xdb ;;
	    ad)	echo ada adb ;;
	    lp)	echo lp ;;
	    mt)	echo ftape ;;
	    qft) echo ftape ;;
	    loop) echo loop ;;
	    md)	echo md ;;
	    ibcs2) echo ibcs2 ;;
	    tpqic02) echo qic ;;
	    sound) echo audio ;;
	    logiscan) echo logiscan ;;
	    ac4096) echo ac4096 ;;
	    hw)	echo helloworld ;; # cute
	    sbpcd | sbpcd[123])	echo $1 ;;
	    joystick) echo js ;;
	    input) echo input ;;
	    apm_bios) echo apm ;;
	    dcf) echo dcf ;;
	    aztcd) echo aztcd ;;
	    cm206cd) echo cm206cd ;;
	    gscd) echo gscd ;;
	    pcmcia) ;; # taken care of by its own driver
	    ttyC) echo cyclades ;;
	    isdn) echo isdnmodem isdnbri dcbri ;;
	    vcs) 	;; # ummm ?
	    pty) echo pty ;;
	    misc) echo misc ;;
	    3dfx) echo 3dfx ;;
	    agpgart) echo agpgart ;;
	    microcode) echo microcode ;;
	    ipmi|ipmikcs) echo ipmi ;;
	    fb)	echo fb ;;
	    nb|drbd) echo nb0 nb1 nb2 nb3 nb4 nb5 nb6 nb7;;
	    netlink) echo netlink ;;
	    tap) echo netlink ;;
	    hamradio) echo hamradio ;;
	    snd) 	;;
	    ptm) 	;;
	    pts) 	;;
	    ttyB)  	(for l in 0 1 2 3 4 5 6 7 ; do
		  	     echo -n ttyB$l " "
		 	 done) ; echo
		  	;;
	    ttyS) echo ttyS0 ttyS1 ttyS2 ttyS3 ttyS4 ;;
	    ttyI) echo ttyI0 ttyI1 ttyI2 ttyI3 ;;
	    ircomm|irlpt)	irda ;;
	    ppp) echo ppp ;;
	    usb) echo usb ;;
	    dpt_i2o) echo dpti ;;
	    bluetooth)	echo bluetooth ;;
	    lvm)    ;; # taken care of by LVM userspace tools
	    ramdisk) echo ram ;;
	    null) echo std ;;
	    zero) echo std ;;
	    *)	echo $1
	esac
	shift
    done
}

for arg in `cvt $*`
do
	# this is to make the case patterns work as expected in all locales
	LC_ALL=C
	case $arg in
	generic)
		# pick the right generic-<arch> using dpkg's knowledge
		case `dpkg --print-architecture` in
			alpha)
				$0 $opts generic-alpha
				;;
			arm|armeb|armel)
				$0 $opts generic-arm
				;;
			hppa)
				$0 $opts generic-hppa
				;;
			i386|lpia)
				$0 $opts generic-i386
				;;
			amd64)
				$0 $opts generic-i386
				;;
			ia64)
				$0 $opts generic-ia64
				;;
			m68k)
				$0 $opts generic-m68k
				;;
			mips)
				$0 $opts generic-mips
				;;
			mipsel)
				$0 $opts generic-mipsel
				;;
			powerpc)
				$0 $opts generic-powerpc
				;;
			ppc64)
				$0 $opts generic-powerpc
				;;
			s390)
				$0 $opts generic-s390
				;;
			sh*)	
				$0 $opts generic-sh
				;;
			sparc)
				$0 $opts generic-sparc
				;;
			*)
				echo "$0: no support for generic on this arch" >&2
				exit 1
				;;
		esac
		;;
	generic-alpha)
		$0 $opts std
		$0 $opts fd
		$0 $opts fd0 fd1
		$0 $opts hd sd
		$0 $opts xda xdb
		$0 $opts scd0 scd1
		$0 $opts st0 st1
		$0 $opts sg
		$0 $opts pty
		$0 $opts console
		$0 $opts ttyS0 ttyS1 ttyS2 ttyS3 ttyS4
		$0 $opts busmice
		$0 $opts lp
		$0 $opts par
		$0 $opts audio
		$0 $opts fb
		$0 $opts dac960
		;;
	generic-arm)
		$0 $opts std
		$0 $opts fd
		$0 $opts fd0 fd1
		$0 $opts hd sd
		$0 $opts xda xdb
		$0 $opts scd0 scd1
		$0 $opts st0 st1
		$0 $opts sg
		$0 $opts pty
		$0 $opts console
		$0 $opts ttyS0 ttyS1 ttyS2 ttyS3 ttyS4
		$0 $opts busmice
		makedev sunmouse  c 10 6 $mouse
		$0 $opts lp
		$0 $opts par
		$0 $opts audio
		$0 $opts fb
		;;
	generic-hppa)
		$0 $opts std
		$0 $opts fd
		$0 $opts fd0 fd1
		$0 $opts hd sd
		$0 $opts scd0 scd1
		$0 $opts st0 st1
		$0 $opts sg
		$0 $opts pty
		$0 $opts console
		$0 $opts ttyS0 ttyS1 ttyS2 ttyS3 ttyS4
		$0 $opts ttyB0 ttyB1 ttyB2 ttyB3 ttyB4 ttyB5 ttyB6 ttyB7
		$0 $opts busmice
		$0 $opts lp
		$0 $opts par
		$0 $opts audio
		$0 $opts fb
		$0 $opts rtc
		;;
	generic-i386 | generic-i686)
		$0 $opts std
		$0 $opts fd
		$0 $opts fd0 fd1
		$0 $opts hd sd
		$0 $opts xda xdb
		$0 $opts scd0 scd1
		$0 $opts st0 st1
		$0 $opts sg
		$0 $opts pty
		$0 $opts console
		$0 $opts ttyS0 ttyS1 ttyS2 ttyS3 ttyS4
		$0 $opts busmice
		$0 $opts input
		$0 $opts lp
		$0 $opts par
		$0 $opts audio
		$0 $opts fb
		$0 $opts isdn-io eda edb sonycd mcd mcdx cdu535
		$0 $opts optcd sjcd cm206cd gscd 
		$0 $opts lmscd sbpcd aztcd bpcd dac960 dpti ida ataraid cciss
		$0 $opts i2o.hda i2o.hdb i2o.hdc i2o.hdd
		;;
	generic-ia64)
		$0 $opts std
		$0 $opts fd
		$0 $opts fd0 fd1
		$0 $opts hd sd
		$0 $opts scd0 scd1
		$0 $opts st0 st1
		$0 $opts sg
		$0 $opts pty
		$0 $opts console
		$0 $opts ttyS0 ttyS1 ttyS2 ttyS3 ttyS4 ttyS5
		$0 $opts busmice
		$0 $opts input
		$0 $opts lp
		$0 $opts par
		$0 $opts audio
		$0 $opts fb
		$0 $opts efirtc
		;;
	generic-m68k)
		$0 $opts std
		$0 $opts fd
		$0 $opts fd0 fd1
		$0 $opts hd sd
		$0 $opts scd0 scd1
		$0 $opts sg
		$0 $opts ada adb adc add ade adf
		$0 $opts pty
		$0 $opts console
		$0 $opts ttyS0 ttyS1 ttyS2 ttyS3 ttyS4 ttyS5
		$0 $opts m68k-mice
		$0 $opts lp
		$0 $opts par
		$0 $opts nvram
		$0 $opts audio
		$0 $opts fb
		;;
	generic-mips)
		$0 $opts std
		$0 $opts fd
		$0 $opts fd0 fd1
		$0 $opts hd sd
		$0 $opts scd0 scd1
		$0 $opts st0 st1
		$0 $opts sg
		$0 $opts pty
		$0 $opts console
		$0 $opts ttyS0 ttyS1 ttyS2 ttyS3 ttyS4
		$0 $opts lp
		$0 $opts par
		$0 $opts audio
		$0 $opts fb
		$0 $opts busmice
		;;
	generic-mipsel)
		$0 $opts std
		$0 $opts fd
		$0 $opts fd0 fd1
		$0 $opts hd sd
		$0 $opts scd0 scd1
		$0 $opts st0 st1
		$0 $opts sg
		$0 $opts pty
		$0 $opts console
		$0 $opts ttyS0 ttyS1 ttyS2 ttyS3 ttyS4
		$0 $opts lp
		$0 $opts par
		$0 $opts audio
		$0 $opts fb
		$0 $opts rtc
		;;
	generic-powerpc)
		$0 $opts std
		$0 $opts fd
		$0 $opts fd0 fd1
		$0 $opts hd sd
		$0 $opts scd0 scd1
		$0 $opts st0 st1
		$0 $opts sg
		$0 $opts pty
		$0 $opts console
		$0 $opts ttyS0 ttyS1 ttyS2 ttyS3 ttyS4
		$0 $opts busmice
		$0 $opts m68k-mice
		$0 $opts input
		$0 $opts lp
		$0 $opts par
		$0 $opts nvram
		$0 $opts audio
		$0 $opts adb
		$0 $opts fb
		$0 $opts rtc
		$0 $opts isdn-io
		;;
	generic-s390)
		$0 $opts std
		$0 $opts fd
		$0 $opts dasda dasdb dasdc dasdd dasde dasdf dasdg dasdh \
			dasdi dasdj dasdk dasdl dasdm dasdn dasdo dasdp \
			dasdq dasdr dasds dasdt dasdu dasdv dasdw dasdx \
			dasdy dasdz
		$0 $opts pty
		$0 $opts consoleonly
		$0 $opts rtc
		;;
	generic-sh)
		$0 $opts std
		$0 $opts fd
		$0 $opts fd0 fd1
		$0 $opts hd sd
		$0 $opts scd0 scd1
		$0 $opts st0 st1
		$0 $opts sg
		$0 $opts pty
		$0 $opts console
		$0 $opts ttyS0 ttyS1 ttyS2 ttyS3 ttyS4  
		$0 $opts ttySC0 ttySC1 ttySC2 ttySC3 
		$0 $opts lp
		$0 $opts par
		$0 $opts audio
		$0 $opts fb
		$0 $opts rtc
		;;
	generic-sparc)
		$0 $opts std
		$0 $opts fd
		$0 $opts fd0 fd1
		$0 $opts hd sd
		$0 $opts scd0 scd1
		$0 $opts st0 st1
		$0 $opts sg
		$0 $opts pty
		$0 $opts console
		$0 $opts ttyS0 ttyS1 ttyS2 ttyS3 ttyS4
		$0 $opts busmice
		$0 $opts fb
		$0 $opts rtc
		makedev kbd  c 11 0 $cons
		makedev sunmouse  c 10 6 $mouse
		symlink mouse sunmouse
		makedev openprom  c 10 139 root root 0664
		;;
	local)
		$0.local $opts
		;;
	std)
		makedev mem  c 1 1 $kmem
		makedev kmem c 1 2 $kmem
		makedev null c 1 3 $public
		makedev port c 1 4 $kmem
		makedev zero c 1 5 $public
		symlink core $procfs/kcore
		makedev full c 1 7 $public
		makedev random c 1 8 $public
		makedev urandom c 1 9 $public
		makedev tty  c 5 0 $tty
		$0 $opts ram
		$0 $opts loop
		;;
	hamradio)
		$0 $opts scc
		$0 $opts bc
		;;
	scc)
		for unit in 0 1 2 3 4 5 6 7 
		do
			makedev scc$unit c 34 $unit $system
		done
		;;
	mtd)	
		for unit in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
		do
			makedev mtd$unit c 90 `math $unit \* 2` $system
		done
		;;
	bc)	
		for unit in 0 1 2 3
		do
			makedev bc$unit c 51 $unit $system
		done
		;;
	random)
		makedev random c 1 8 $public
		;;
	urandom)
		makedev urandom c 1 9 $readable
		;;
	ram)
		for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 ; do
			makedev ram$i  b 1 $i $disk
		done
		symlink ram ram1
		;;
	ram[0-9]|ram1[0-6])
		unit=`suffix $arg ram`
		makedev ram$unit b 1 $unit $disk
		;;
	initrd)
		makedev initrd b 1 250 $disk
		;;
	raw)
		makedev rawctl c 162 0 $disk
		mkdir -p raw
		for i in 1 2 3 4 5 6 7 8; do
			makedev raw/raw$i c 162 $i $disk
		done
		;;
	consoleonly)
		makedev tty0 c 4 0 $cons
		#	new kernels need a device, old ones a symlink... sigh
		kern_rev1=`uname -r | sed -e 's@^\([^.]*\)\..*@\1@'`
		kern_rev2=`uname -r | sed -e 's@^[^.]*\.\([^.]*\)\..*@\1@'`
		if [ $kern_rev1 -gt 2 ]
		then
			makedev console c 5 1 $cons
		else
			if [ $kern_rev1 -eq 2 ] && [ $kern_rev2 -ge 1 ]
			then
				makedev console c 5 1 $cons
			else
				symlink console tty0
			fi
		fi
		;;
	console)
		$0 $opts consoleonly
		major=`Major vcs 7`       # not fatal
		[ "$major" ] && makedev vcs0 c $major 0 $cons
		symlink vcs vcs0
		[ "$major" ] && makedev vcsa0 c $major 128 $cons
		symlink vcsa vcsa0
		# individual vts
		line=1
		while [ $line -le $MAXVT ] && [ $line -le 63 ]
		do
			makedev tty$line c 4 $line $cons
			[ "$major" ] && makedev vcs$line c $major $line $cons
			[ "$major" ] && makedev vcsa$line c $major `math $line + 128` $cons
			line=`math $line + 1`
		done
		;;
	adb)
		# pick the right arch device using dpkg's knowledge
		case `dpkg --print-architecture` in
			powerpc)
				# ADB bus devices (char)
				makedev adb c 56 0 $mouse
				makedev adbmouse c 10 10 $mouse
				;;
			m68k)
				# ACSI disk 2, whole device (block)
				makedev adb b 28 16 $disk
				for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
				do
					minor=$(( 16 + $part ))
					makedev adb$part b 28 $minor $disk
				done
				;;
			*)
				echo "no support for adb on this arch" >&2
				exit 1
				;;
		esac
		;;
	raw1394)
		makedev raw1394 c 171 0 $disk
		;;
	video1394)
		rm -f video1394
		mkdir -p video1394
		for i in `seq 0 15`
		do
			makedev video1394/$i c 171 `math 16 + $i` $video
		done
		;;
	alsa)
		echo "You requested 'alsa' devices.  Please install the alsa-base package instead,"
		echo "which creates and maintains device information for ALSA."
		;;
	nvram)
		makedev nvram c 10 144 $mouse
		;;
	tty[1-9]|tty[1-5][0-9]|tty[6][0-3])
		line=`suffix $arg tty`
		makedev tty$line c 4 $line $cons
		;;
	ttyS[0-9]|ttyS[1-5][0-9]|ttyS[6][0-3])
		line=`suffix $arg ttyS`
		minor=`math 64 + $line`
		makedev ttyS$line c 4 $minor $dialout
		;;
	ttySC[0-3])
		line=`suffix $arg ttySC`
		minor=`math 8 + $line`
		makedev ttySC$line c 204 $minor $dialout
 		;;
	ttyB[0-7])
		minor=`suffix $arg ttyB`
		makedev ttyB$minor c 11 $minor $dialout
		;;
	pty[a-ep-z])
		bank=`suffix $arg pty`
		base=`index pqrstuvwxyzabcde $bank`
		base=`math $base \* 16`
		for i in 0 1 2 3 4 5 6 7 8 9 a b c d e f
		do
			j=`index 0123456789abcdef $i`
			makedev pty$bank$i c 2 `math $base + $j` $tty
			makedev tty$bank$i c 3 `math $base + $j` $tty
		done
		;;
	pty)
		ptysufs=""
		for i in p q r s t u v w x y z a b c d e
		do
			ptysufs="$ptysufs pty$i"
		done
		$0 $opts $ptysufs ptmx
		;;
	ptmx)
		# master pty multiplexer for 2.1 kernels
		makedev ptmx c 5 2 $tty
		;;
	cyclades|ttyC)
		major1=`Major ttyC 19` || continue
		#major2=`Major cub 20` || continue
		for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 \
			  16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 
		do
			makedev ttyC$i c $major1 $i $dialout
			#makedev cub$i c $major2 $i $dialout
		done
		;;
	stallion|ttyE)
		major1=`Major ttyE 24` || continue
		#major2=`Major cue 25` || continue
		majorc=28
		minor=0
		until [ $minor -gt 256 ]
		do
			makedev ttyE$minor c $major1 $minor $dialout
			#makedev cue$minor c $major2 $minor $dialout
			minor=`math $minor + 1`
		done
		for i in 0 1 2 3
		do
			makedev staliomem$i c $majorc $i $private
		done
		;;
	chase|ttyH)
		major1=`Major ttyH 17` || continue
		#major2=`Major cuh 18` || continue
		minor=0
		until [ $minor -gt 16 ] # tell me if 16 is wrong
		do
			makedev ttyH$minor c $major1 $minor $dialout
			#makedev cuh$minor c $major2 $minor $dialout
			minor=`math $minor + 1`
		done
		;;
	rocketport|ttyR)
		major1=`Major ttyR 46` || continue
		#major2=`Major cur 47` || continue
		minor=0
		until [ $minor -gt 64 ] # tell me if 64 is wrong
		do
			makedev ttyR$minor c $major1 $minor $dialout
			#makedev cur$minor c $major2 $minor $dialout
			minor=`math $minor + 1`
		done
		;;
	ttyV)
		major1=`Major ttyV 105` || continue
		#major2=`Major cuv 106` || continue
		minor=0
		until [ $minor -gt 16 ] # tell me if 16 is wrong
		do
			makedev ttyV$minor c $major1 $minor $dialout
			#makedev cuv$minor c $major2 $minor $dialout
			minor=`math $minor + 1`
		done
		;;
	digi|ttyD)
		major1=`Major ttyD 22` || continue
		#major2=`Major cud 23` || continue
		minor=0
		until [ $minor -gt 16 ] # tell me if 16 is wrong
		do
			makedev ttyD$minor c $major1 $minor $dialout
			#makedev cud$minor c $major2 $minor $dialout
			minor=`math $minor + 1`
		done
		;;
	specialix|ttyX)
		major1=`Major ttyX 32` || continue
		#major2=`Major cux 33` || continue
		minor=0
		until [ $minor -gt 16 ] # tell me if 16 is wrong
		do
			makedev ttyX$minor c $major1 $minor $dialout
			#makedev cux$minor c $major2 $minor $dialout
			minor=`math $minor + 1`
		done
		;;
	specialixIO8|ttyW)
		major1=`Major ttyW 75` || continue
		#major2=`Major cuw 76` || continue
		minor=0
		until [ $minor -gt 16 ] # tell me if 16 is wrong
		do
			makedev ttyW$minor c $major1 $minor $dialout
			#makedev cuw$minor c $major2 $minor $dialout
			minor=`math $minor + 1`
		done
		;;
	PAM|ttyM)
		major1=`Major ttyM 79` || continue
		#major2=`Major cum 80` || continue
		minor=0
		until [ $minor -gt 16 ] # tell me if 16 is wrong
		do
			makedev ttyM$minor c $major1 $minor $dialout
			#makedev cum$minor c $major2 $minor $dialout
			minor=`math $minor + 1`
		done
		;;
	riscom|ttyL)
		major=`Major ttyL 48` || continue
		minor=0
		until [ $minor -gt 16 ] # tell me if 16 is wrong
		do
			makedev ttyL$minor c $major $minor $dialout
			minor=`math $minor + 1`
		done
		;;
	computone|ttyF)
		major=`Major ttyF 71` || continue
		#major2=`Major cuf 72` || continue
		minor=0
		until [ $minor -gt 255 ]
		do
			makedev ttyF$minor c $major $minor $dialout
			#makedev cuf$minor c $major2 $minor $dialout
			minor=`math $minor + 1`
		done
		major=73
		for i in 0 4 8 12
		do
			makedev ip2ipl$i  c $major $i $private
			makedev ip2stat$i c $major `math $i + 1` $private
		done
		;;
	ESP|ttyP)
		major=`Major ttyP 57` || continue
		#major2=`Major cup 58` || continue
		minor=0
		until [ $minor -gt 4 ] # tell me if 4 is wrong
		do
			makedev ttyP$minor c $major $minor $dialout
			#makedev cup$minor c $major2 $minor $dialout
			minor=`math $minor + 1`
		done
		;;
	COMX|comx)
		major=`Major comx 88` || continue
		minor=0
		until [ $minor -gt 4 ] # tell me if 4 is wrong
		do
			makedev comx$minor c $major $minor $private
			minor=`math $minor + 1`
		done
		;;
	isdnmodem|ttyI)
		major1=`Major ttyI 43` || continue
		#major2=`Major cui 44` || continue
		minor=0
		until [ $minor -gt 63 ]
		do
			makedev ttyI$minor c $major1 $minor $dialout
			#makedev cui$minor c $major2 $minor $dialout
			minor=`math $minor + 1`
		done
		;;
	isdnbri)
		major=45
		minor=0
		until [ $minor -gt 63 ]
		do
			makedev isdn$minor c $major $minor $dialout
			makedev isdnctrl$minor c $major `math $minor + 64` $dialout
			makedev ippp$minor c $major `math $minor + 128` $dialout
			minor=`math $minor + 1`
		done
		makedev isdninfo c $major 255 $private
		;;
	dcbri)
		major=52
		for i in 0 1 2 3
		do
			makedev dcbri$i c $major $i $dialout
		done
		;;
	capi)
		major=68
		makedev capi20 c $major 0 $dialout
		for i in 0 1 2 3 4 5 6 7 8 9
		do
			makedev capi20.0$i c $major `math $i + 1` $dialout
		done
		for i in 10 11 12 13 14 15 16 17 18 19
		do
			makedev capi20.$i c $major `math $i + 1` $dialout
		done
		;;
	ubd)
		major=98
		for devicenum in 0 1 2 3 4 5 6 7
		do
			device=ubd`substr abcdefgh $(($devicenum + 1))`
			baseminor=`math $devicenum \* 16`
			makedev $device b $major $baseminor $disk
			for partition in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
			do
				minor=`math $baseminor + $partition`
				makedev $device$partition b $major $minor $disk
			done
		done
		;;
	fb)
		for i in 0 1 2 3 4 5 6 7
		do
			makedev fb$i c 29 $i $video
		done
		;;
	fb[0-7])
		dev=`suffix $arg fb`
		makedev fb$dev c 29 $dev $video
		;;
	netlink|tap|tap[0-9]|tap1[0-5])
		makedev route     c 36 0 $coda
		makedev skip      c 36 1 $coda
		makedev fwmonitor c 36 3 $coda
		for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
		do
			makedev tap$i c 36 `math $i + 16` $coda
		done
		;;
	tun)
		mkdir -p net
		makedev net/tun c 10 200 $system
		;;
	lp)
		major=`Major lp 6` || continue
		makedev ${arg}0 c $major 0 $printer
		makedev ${arg}1 c $major 1 $printer
		makedev ${arg}2 c $major 2 $printer
		;;
	par)
		major=`Major lp 6` || continue
		makedev ${arg}0 c $major 0 $printer
		makedev ${arg}1 c $major 1 $printer
		makedev ${arg}2 c $major 2 $printer
		;;
	parport)
		major=`Major parport 99` || continue
		makedev ${arg}0 c $major 0 $printer
		makedev ${arg}1 c $major 1 $printer
		makedev ${arg}2 c $major 2 $printer
		;;
	slm)
		major=`Major slm 28` || continue
		for i in 0 1 2 3
		do
			makedev slm c $major $i $printer
		done
		;;
	input)
		major=`Major pcsp 13` || continue
		mkdir -p input
		for i in 0 1 2 3
		do
			makedev input/js$i c $major $i $mouse
			makedev input/mouse$i c $major `math $i + 32` $mouse
			makedev input/event$i c $major `math $i + 64` $mouse
		done
		makedev input/mice c $major 63 $mouse
		;;
	busmice)
		major=`Major mouse 10` || continue
		makedev logibm	  c $major 0 $mouse
		makedev psaux     c $major 1 $mouse
		makedev inportbm  c $major 2 $mouse
		makedev atibm     c $major 3 $mouse
		makedev jbm       c $major 4 $mouse
		;;
	m68k-mice)
		major=`Major mouse 10` || continue
		makedev amigamouse c $major 4 $mouse
		makedev atarimouse c $major 5 $mouse
		makedev amigamouse1 c $major 7 $mouse
		makedev adbmouse  c $major 10 $mouse
		;;
	3dfx)
		major=`Major $arg 107` || continue
		makedev $arg	c $major 0 $video
		;;
	agpgart)
		major=`Major $arg 10` || continue
		makedev $arg	c $major 175 $video
		;;
	hwrng)
		major=`Major $arg 10` || continue
		makedev $arg	c $major 183 $private
		;;
	mcelog)
		major=`Major $arg 10` || continue
		makedev $arg	c $major 227 $private
		;;
	cpu|microcode)
		mkdir -p cpu
		makedev cpu/microcode c 10 184 $private
		for i in 0 1 2 3
		do
			mkdir -p cpu/$i
			makedev cpu/$i/msr   c 202 $i $private
			makedev cpu/$i/cpuid c 203 $i $private
		done
		;;
	ipmi|ipmikcs)
		major=`Major ipmikcs 10` || continue
		makedev ipmikcs	c $major 173 $private
		;;
	irda)
		for i in 0 1
		do
			makedev ircomm$i c 161 $i $dialout
			makedev irlpt$i  c 161 `math $i + 16` $printer
		done
		;;
	irnet)
		makedev irnet c 10 187 $system
		;;
	cbm)
		makedev cbm c 10 177 $floppy
		;;
	misc)
		major=`Major mouse 10` || continue
		makedev logibm	  c $major 0 $mouse
		makedev psaux     c $major 1 $mouse
		makedev inportbm  c $major 2 $mouse
		makedev atibm     c $major 3 $mouse
		makedev jbm       c $major 4 $mouse
		makedev amigamouse c $major 4 $mouse
		makedev atarimouse c $major 5 $mouse
		makedev sunmouse  c $major 6 $mouse
		makedev amigamouse1 c $major 7 $mouse
		makedev smouse    c $major 8 $mouse
		makedev pc110pad  c $major 9 $mouse
		makedev adbmouse  c $major 10 $mouse
		makedev beep      c $major 128 $mouse
		makedev modreq    c $major 129 $mouse
		makedev watchdog  c $major 130 $mouse
		makedev temperature c $major 131 $mouse
		makedev hwtrap    c $major 132 $mouse
		makedev exttrp    c $major 133 $mouse
		makedev apm_bios  c $major 134 $mouse
		makedev rtc       c $major 135 $mouse
		makedev openprom  c $major 139 root root 0664
		makedev relay8    c $major 140 $mouse
		makedev relay16   c $major 141 $mouse
		makedev msr       c $major 142 $mouse
		makedev pciconf   c $major 143 $mouse
		makedev nvram     c $major 144 $mouse
		makedev hfmodem   c $major 145 $mouse
		makedev led       c $major 151 $mouse
		makedev mergemem  c $major 153 $mouse
		makedev pmu       c $major 154 $mouse
		;;
	fuse)
		makedev fuse      c 10 229 $system
		;;
	pmu)
		major=`Major mouse 10` || continue
		makedev pmu       c $major 154 $mouse
		;;
	thinkpad)
		major=`Major mouse 10` || continue
		mkdir -p thinkpad
		makedev thinkpad/thinkpad c $major 170 $mouse
		;;
        rtc)
		major=`Major mouse 10` || continue
		makedev rtc       c $major 135 $mouse
		;;
	efirtc)
		major=`Major mouse 10` || continue
		makedev efirtc    c $major 136 $mouse
 		;;
	mwave)
		makedev mwave     c 10 219 $mouse
		;;
	systrace)
		makedev systrace  c 10 226 $private
		;;
	uinput)
		mkdir -p input
		makedev input/uinput  c 10 223 $mouse
		;;
	js)
		major=`Major Joystick 13` || continue
		for unit in 0 1 2 3
		do
			makedev js$unit c $major $unit $readable
			makedev djs$unit c $major `math $unit + 128` $readable
		done
		;;
	fd[0-7])
		major=`Major fd 2` || continue
		base=`suffix $arg fd`
		if [ $base -ge 4 ]
		then
			base=`math $base + 124`
		fi
		makedev ${arg} b $major $base $floppy
		makedev ${arg}d360  b $major `math $base +  4` $floppy
		makedev ${arg}h1200 b $major `math $base +  8` $floppy
		makedev ${arg}u360  b $major `math $base + 12` $floppy
		makedev ${arg}u720  b $major `math $base + 16` $floppy
		makedev ${arg}h360  b $major `math $base + 20` $floppy
		makedev ${arg}h720  b $major `math $base + 24` $floppy
		makedev ${arg}u1440 b $major `math $base + 28` $floppy
		makedev ${arg}u2880 b $major `math $base + 32` $floppy
		makedev ${arg}CompaQ b $major `math $base + 36` $floppy

		makedev ${arg}h1440 b $major `math $base + 40` $floppy
		makedev ${arg}u1680 b $major `math $base + 44` $floppy
		makedev ${arg}h410  b $major `math $base + 48` $floppy
		makedev ${arg}u820  b $major `math $base + 52` $floppy
		makedev ${arg}h1476 b $major `math $base + 56` $floppy
		makedev ${arg}u1722 b $major `math $base + 60` $floppy
		makedev ${arg}h420  b $major `math $base + 64` $floppy
		makedev ${arg}u830  b $major `math $base + 68` $floppy
		makedev ${arg}h1494 b $major `math $base + 72` $floppy
		makedev ${arg}u1743 b $major `math $base + 76` $floppy
		makedev ${arg}h880  b $major `math $base + 80` $floppy
		makedev ${arg}u1040 b $major `math $base + 84` $floppy
		makedev ${arg}u1120 b $major `math $base + 88` $floppy
		makedev ${arg}h1600 b $major `math $base + 92` $floppy
		makedev ${arg}u1760 b $major `math $base + 96` $floppy
		makedev ${arg}u1920 b $major `math $base + 100` $floppy
		makedev ${arg}u3200 b $major `math $base + 104` $floppy
		makedev ${arg}u3520 b $major `math $base + 108` $floppy
		makedev ${arg}u3840 b $major `math $base + 112` $floppy
		makedev ${arg}u1840 b $major `math $base + 116` $floppy
		makedev ${arg}u800  b $major `math $base + 120` $floppy
		makedev ${arg}u1600 b $major `math $base + 124` $floppy
		;;
	ed[a-b])
		major=`Major ed 36` || continue
		unit=`suffix $arg ed`
		base=`index ab $unit`
		base=`math $base \* 64`
		makedev ed$unit b $major $base $disk
		for part in 1 2 3 4 5 6 7 8 # 9 10 11 12 13 14 15 16 17 18 19 20
		do
			makedev ed$unit$part b $major `math $base + $part` $disk
		done
		;;
	hd[a-b])
		major=`Major ide0` || major=`Major hd 3` || continue
		unit=`suffix $arg hd`
		base=`index ab $unit`
		base=`math $base \* 64`
		makedev hd$unit b $major $base $disk
		for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
		do
			makedev hd$unit$part b $major `math $base + $part` $disk
		done
		;;
	hd[c-d])
		major=`Major ide1 22` || continue
		unit=`suffix $arg hd`
		base=`index cd $unit`
		base=`math $base \* 64`
		makedev hd$unit b $major $base $disk
		for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
		do
			makedev hd$unit$part b $major $(( $base + $part )) $disk
		done
		;;
	hd[e-f])
		major=`Major ide2 33` || continue
		unit=`suffix $arg hd`
		base=`index ef $unit`
		base=`math $base \* 64`
		makedev hd$unit b $major $base $disk
		for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
		do
			makedev hd$unit$part b $major $(( $base + $part )) $disk
		done
		;;
	hd[g-h])
		major=`Major ide3 34` || continue
		unit=`suffix $arg hd`
		base=`index gh $unit`
		base=`math $base \* 64`
		makedev hd$unit b $major $base $disk
		for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
		do
			makedev hd$unit$part b $major $(( $base + $part )) $disk
		done
		;;
	hd[i-j])
		major=`Major ide4 56` || continue
		unit=`suffix $arg hd`
		base=`index ij $unit`
		base=`math $base \* 64`
		makedev hd$unit b $major $base $disk
		for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
		do
			makedev hd$unit$part b $major $(( $base + $part )) $disk
		done
		;;
	hd[k-l])
		major=`Major ide5 57` || continue
		unit=`suffix $arg hd`
		base=`index kl $unit`
		base=`math $base \* 64`
		makedev hd$unit b $major $base $disk
		for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
		do
			makedev hd$unit$part b $major $(( $base + $part )) $disk
		done
		;;
	hd[m-n])
		major=`Major ide6 88` || continue
		unit=`suffix $arg hd`
		base=`index mn $unit`
		base=`math $base \* 64`
		makedev hd$unit b $major $base $disk
		for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
		do
			makedev hd$unit$part b $major $(( $base + $part )) $disk
		done
		;;
	hd[o-p])
		major=`Major ide7 89` || continue
		unit=`suffix $arg hd`
		base=`index op $unit`
		base=`math $base \* 64`
		makedev hd$unit b $major $base $disk
		for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
		do
			makedev hd$unit$part b $major $(( $base + $part )) $disk
		done
		;;
	hd[q-r])
		major=`Major ide8 90` || continue
		unit=`suffix $arg hd`
		base=`index qr $unit`
		base=`math $base \* 64`
		makedev hd$unit b $major $base $disk
		for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
		do
			makedev hd$unit$part b $major $(( $base + $part )) $disk
		done
		;;
	hd[s-t])
		major=`Major ide9 91` || continue
		unit=`suffix $arg hd`
		base=`index st $unit`
		base=`math $base \* 64`
		makedev hd$unit b $major $base $disk
		for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
		do
			makedev hd$unit$part b $major $(( $base + $part )) $disk
		done
		;;
	ub|uba)	
		major=180
		makedev uba b $major 0 $disk
		for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
		do
			makedev uba$part b $major $part $disk
		done
		;;
	ht0)
		major=`Major ht0 37` || continue
		# Only one IDE tape drive is currently supported; ht0.
		makedev ht0 c $major 0 $tape
		makedev nht0 c $major 128 $tape
		;;
	pt)
		major=`Major pt 96` || continue
		for i in 0 1 2 3
		do
			makedev pt$i c $major $i $tape
			makedev npt$i c $major `math $i + 128` $tape
		done
		;;
	xd[a-d])
		major=`Major xd 13` || continue
		unit=`suffix $arg xd`
		base=`index abcd $unit`
		base=`math $base \* 64`
		makedev xd$unit b $major $base $disk
		for part in 1 2 3 4 5 6 7 8 # 9 10 11 12 13 14 15 16 17 18 19 20
		do
			makedev xd$unit$part b $major $(( $base + $part )) $disk
		done
		;;
	sd[a-z])
		major=`Major sd 8` || continue
		unit=`suffix $arg sd`
		base=`index abcdefghijklmnopqrstuvwxyz $unit`
		base=$(( $base * 16 ))
		if [ $base -lt 256 ]; then
			major=8
		else
			major=65
			base=$(( $base - 256 ))
		fi
		makedev sd$unit b $major $base $disk
		for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
		do
			minor=$(( $base + $part ))
			makedev sd$unit$part b $major $minor $disk
		done
		;;
	sd[a-d][a-z])
		unit=`suffix $arg sd`
		unitmaj=`first $unit`
		unitmin=`second $unit`
		basemaj=`index Xabcd $unitmaj`
		basemin=`index abcdefghijklmnopqrstuvwxyz $unitmin`
		basemaj=`math $basemaj \* 416`
		basemin=`math $basemin \* 16`
		base=`math $basemaj + $basemin`
		basemaj=`math $base / 256`
		base=`math $base % 256`
		major=`math basemaj \+ 64`
		if [ $major -gt 71 ]; then
			echo "$0: don't know how to make device \"$arg\"" >&2
			exit 0
		fi
		makedev sd$unit b $major $base $disk
		for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
		do
			minor=$(( $base + $part ))
			makedev sd$unit$part b $major $minor $disk
		done
                ;;
	i2o.hd[a-z])
		[ -d i2o ] || {
		    mkdir i2o
		    chown root:root i2o
		    chmod 755 i2o
      		    [ -e i2o/ctl ] || makedev i2o/ctl c 10 166 $disk
		}
		unit=`suffix $arg i2o.hd`
		base=`index abcdefghijklmnopqrstuvwxyz $unit`
		base=$(( $base * 16 ))
		if [ $base -lt 256 ]; then
		    major=80
		else
		    major=81
		    base=$(( $base - 256 ))
		fi
		makedev i2o/hd$unit b $major $base $disk
		for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
		do
			minor=$(( $base + $part ))
			makedev i2o/hd$unit$part b $major $minor $disk
		done
		;;
	i2o.hd[a-d][a-z])
	    [ -d i2o ] || {
		mkdir i2o
		chown root:root i2o
		chmod 755 i2o
      		[ -e i2o/ctl ] || makedev i2o/ctl c 10 166 $disk
	    }
		unit=`suffix $arg i2o.hd`
		unitmaj=`first $unit`
		unitmin=`second $unit`
		basemaj=`index Xabcd $unitmaj`
		basemin=`index abcdefghijklmnopqrstuvwxyz $unitmin`
		basemaj=`math $basemaj \* 416`
		basemin=`math $basemin \* 16`
		base=`math $basemaj + $basemin`
		basemaj=`math $base / 256`
		base=`math $base % 256`
		major=`math basemaj \+ 80`
		if [ $major -gt 87 ]; then
		    echo "$0: don't know how to make device \"$arg\"" >&2
		    exit 0
		fi
		makedev i2o/hd$unit b $major $base $disk
		for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
		do
		    minor=$(( $base + $part ))
			makedev i2o/hd$unit$part b $major $minor $disk
		done
		;;
	dasd[a-z])
	    major=`Major dasd 94` || continue
	    unit=`suffix $arg dasd`
	    base=`index abcdefghijklmnopqrstuvwxyz $unit`
	    base=$(( $base * 4 ))
	    if [ $base -lt 256 ]; then
		major=94
		else
		    major=65
		    base=$(( $base - 256 ))
	    fi
		makedev dasd$unit b $major $base $disk
		for part in 1 2 3
		do
		    minor=$(( $base + $part ))
		    makedev dasd$unit$part b $major $minor $disk
		done
		;;
	ad[a-p])
	    major=`Major ad 28` || continue
	    unit=`suffix $arg ad`
	    base=`index abcdefghijklmnop $unit`
	    base=`math $base \* 16`
	    makedev ad$unit b $major $base $disk
	    for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
	    do
		minor=$(( $base + $part ))
		makedev ad$unit$part b $major $minor $disk
	    done
	    ;;
	dac960)
	    for ctr in 0 1 2 3 4 5 6 7
	    do
		$0 $opts dac960.$ctr
	    done
	    makedev dac960_gam c 10 252 $disk
	    ;;
	dac960.[0-7])
		[ -d rd ] || {
		    mkdir rd
		    chown root:root rd
		    chmod 755 rd
		}
		unit=`suffix $arg dac960.`
		major=`math 48 + $unit`
		minor=0
		for ld in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 \
			    17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
		do
		    makedev rd/c${unit}d${ld} b $major $minor $disk
			minor=`math $minor + 1`
			for part in 1 2 3 4 5 6 7
			do
			    makedev rd/c${unit}d${ld}p$part b $major $minor $disk
			    minor=`math $minor + 1`
			done
		    done
		;;
	dpti)
		major=151
		for ld in 1 2 3 4 5 6 7
		do
		   minor=`math $ld -1`
		   makedev dpti${ld} c $major $minor $disk
                done
                ;;
	ataraid)
		for ctr in 0 1 2 # 3 4 5 6 7
		do
			$0 $opts ataraid.$ctr
		done
		;;
	ataraid.[0-7])
		[ -d ataraid ] || {
			mkdir ataraid
			chown root:root ataraid
			chmod 755 ataraid
		}
                unit=`suffix $arg ataraid.`
                major=114
                minor=`math $unit \* 16`
                makedev ataraid/d${unit} b $major $minor $disk
                for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
                do
                   minor=`math $minor + 1`
                   makedev ataraid/d${unit}p$part b $major $minor $disk
                done
 		;;
	ida)
		for ctr in 0 1 2 # 3 4 5 6 7
		do
			$0 $opts ida.$ctr
		done
		;;
	ida.[0-7])
		[ -d ida ] || {
			mkdir ida
			chown root:root ida
			chmod 755 ida
		}
		unit=`suffix $arg ida.`
		major=`math 72 + $unit`
		minor=0
		for ld in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
		do
		    makedev ida/c${unit}d${ld} b $major $minor $disk
		    minor=`math $minor + 1`
		    for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
		    do
			makedev ida/c${unit}d${ld}p$part b $major $minor $disk
			minor=`math $minor + 1`
		    done
		done
		;;
	cciss)
		for ctr in 0 1 2 # 3 4 5 6 7
		do
			$0 $opts cciss.$ctr
		done
		;;
	cciss.[0-7])
		[ -d cciss ] || {
			mkdir cciss
			chown root:root cciss
			chmod 755 cciss
		}
		unit=`suffix $arg cciss.`
		major=`math 104 + $unit`
		minor=0
		for ld in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
		do
		    makedev cciss/c${unit}d${ld} b $major $minor $disk
		    minor=`math $minor + 1`
		    for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
		    do
			makedev cciss/c${unit}d${ld}p$part b $major $minor $disk
			minor=`math $minor + 1`
		    done
		done
		;;
	rom)
		major=`Major rom 31`
		for i in 0 1 2 3 4 5 6 7
		do
			makedev rom$i    b $major $i $disk
			makedev rrom$i   b $major `math $i +8` $disk
			makedev flash$i  b $major `math $i +16` $disk
			makedev rflash$i b $major `math $i +24` $disk
		done
		;;
	nb[0-7])
		major=`Major nbd 43` || continue
		minor=`suffix $arg nb`
		makedev nb$minor b $major $minor $disk
		;;
	loop)
		for part in 0 1 2 3 4 5 6 7
		do
			makedev loop$part b 7 $part $disk
		done
		;;
	loop[0-9]|loop[1-9][0-9]|loop1[0-9][0-9]|loop2[0-4][0-9]|loop25[0-5])
		minor=`suffix $arg loop`
		makedev loop$minor b 7 $minor $disk
		;;
	md)
		major=`Major md 9` || continue
		for part in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 \
			16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
		do
			makedev md$part b $major $part $disk
		done
		;;
	st[0-7])
		major=`Major st 9`
		unit=`suffix $arg st`
		makedev st${unit}   c $major $unit $tape
		makedev nst${unit}  c $major `math 128 + $unit` $tape

		makedev st${unit}l  c $major `math 32 + $unit` $tape
		makedev nst${unit}l c $major `math 160 + $unit` $tape

		makedev st${unit}m  c $major `math 64 + $unit` $tape
		makedev nst${unit}m c $major `math 192 + $unit` $tape

		makedev st${unit}a  c $major `math 96 + $unit` $tape
		makedev nst${unit}a c $major `math 224 + $unit` $tape
		;;
	qic)
		major=`Major tpqic02 12`
		makedev ntpqic11   c $major   2 $tape
		makedev tpqic11    c $major   3 $tape
		makedev ntpqic24   c $major   4 $tape
		makedev tpqic24    c $major   5 $tape
		makedev ntpqic120  c $major   6 $tape
		makedev tpqic120   c $major   7 $tape
		makedev ntpqic150  c $major   8 $tape
		makedev tpqic150   c $major   9 $tape
		makedev rmt8       c $major   6 $tape
		makedev rmt16      c $major   8 $tape
		makedev tape-d     c $major 136 $tape
		makedev tape-reset c $major 255 $tape
		$0 $opts qft
		;;
	ftape)
		major=`Major qft 27` || continue
		for unit in 0 1 2 3
		do
			makedev qft$unit     c $major $unit $tape
			makedev nqft$unit    c $major `math $unit + 4` $tape
			makedev zqft$unit    c $major `math $unit + 16` $tape
			makedev nzqft$unit   c $major `math $unit + 20` $tape
			makedev rawqft$unit  c $major `math $unit + 32` $tape
			makedev nrawqft$unit c $major `math $unit + 36` $tape
		done
		symlink ftape qft0
		symlink nftape nqft0
		;;
	sr|scd|scd-all)
		major=`Major sr 11` || continue
		for unit in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
		do
			makedev scd$unit b $major $unit $cdrom
			symlink sr$unit scd$unit
		done
		;;
	pktcdvd)
		echo "pktcdvd major number is now dynamic, taking no action"
	#	major=97
	#	for unit in 0 1 2 3
	#	do
	#		makedev pktcdvd$unit b $major $unit $cdrom
	#	done
		;;
	cfs0)
		makedev cfs0 c 67 0 $coda
		;;
	scd[0-9]|scd[0-1][0-9])
		major=`Major sr 11` || continue
		unit=`suffix $arg scd`
		makedev scd$unit b $major $unit $cdrom
		symlink sr$unit scd$unit 
		;;
	ttyI[0-9]|ttyI[1-5][0-9]|ttyI[6][0-3])
		major=43
		unit=`suffix $arg ttyI`
		makedev ttyI$unit c $major $unit $dialout
		;;
	ppp)
		major=108
		makedev ppp c $major 0 $dip
		;;
	ippp[0-9]|ippp[1-5][0-9]|ippp[6][0-3])
		major=45
		unit=`suffix $arg ippp`
		minor=`math $unit + 128`
		makedev ippp$unit c $major $minor $dialout
		;;
	isdn[0-9]|isdn[1-5][0-9]|isdn[6][0-3])
		major=45
		unit=`suffix $arg isdn`
		minor=`math $unit + 0`
		makedev isdn$unit c $major $minor $dialout
		;;
	isdnctrl[0-9]|isdnctrl[1-5][0-9]|isdnctrl[6][0-3])
		major=45
		unit=`suffix $arg isdnctrl`
		minor=`math $unit + 64`
		makedev isdnctrl$unit c $major $minor $dialout
		;;
	isdninfo)
		makedev isdninfo c 45 255 $private
		;;
	isdn-tty)
		major=43
		for unit in 0 1 2 3 4 5 6 7
		do
			makedev ttyI$unit c $major $unit $dialout
		done
		;;
	isdn-ippp)
		major=45
		for unit in 0 1 2 3 4 5 6 7
		do
			makedev ippp$unit c $major `math $unit + 128` $dialout
		done
		;;
	isdn-io)
		for unit in 0 1 2 3 4 5 6 7
		do
			makedev isdn$unit c 45 $unit $dialout
			makedev isdnctrl$unit c 45 `math $unit + 64` $dialout
			makedev ippp$unit c 45 `math $unit + 128` $dialout
		done
		makedev isdninfo c 45 255 $dialout
		;;
	sonycd)
		major=`Major sonycd 15` || continue
		makedev $arg b $major 0 $cdrom
		;;
	mcd)
		major=`Major mcd 23` || continue
		makedev $arg b $major 0 $cdrom
		;;
	mcdx|mcdx[0-4])
		major=`Major $arg 20` || continue
		for unit in 0 1 2 3 4
		do
			makedev mcdx$unit b $major $unit $cdrom
		done
		test -r mcdx || symlink mcdx mcdx0
		;;
	cdu535)
		makedev $arg b 24 0 $cdrom
		;;
	lmscd)
		makedev $arg b 24 0 $cdrom
		;;
	sbpcd|sbpcd[123])
		major=`Major $arg 25` || continue
		base=`suffix ${arg}0 sbpcd`
		for minor in 0 1 2 3
		do
			# XXX
			unit=$(substr 0123456789abcdef $(( $base * 4 + $minor + 1 )) )
			makedev sbpcd$unit b $major $minor $cdrom
		done
		[ $arg = sbpcd ] && symlink $arg ${arg}0
		;;
	aztcd)
		major=`Major $arg 29` || continue
		makedev ${arg}0 b $major 0 $cdrom
		;;
	cm206cd)
		major=`Major $arg 30` || continue
		makedev ${arg}0 b $major 0 $cdrom
		;;
	gscd)
		major=`Major $arg 16` || continue
		makedev ${arg}0 b $major 0 $cdrom
		;;
	pcd)
		for unit in 0 1 2 3 
		do
			makedev pcd$unit b 46 $unit $cdrom
		done
		;;
	bpcd)
		makedev $arg b 41 0 $cdrom
		;;
	optcd)
		makedev $arg b 17 0 $cdrom
		;;
	sjcd)
		makedev $arg b 18 0 $cdrom
		;;
	cfs|coda)
		makedev cfs0 c 67 0 $private
		;;
	xfs|nnpfs|arla)
		makedev xfs0 c 103 0 $private
		makedev nnpfs0 c 103 0 $private
		;;
	logiscan)
		major=`Major logiscan` || continue
		makedev $arg c $major 0 $scanner
		;;
	toshiba)
		major=`Major $arg 10` || continue
		makedev $arg c $major 181 root root 0666
		;;
	m105scan)
		major=`Major m105` || continue
		makedev $arg c $major 0 $scanner
		;;
	ac4096)
		major=`Major ac4096` || continue
		makedev $arg c $major 0 $scanner
		;;
	audio)
		major=`Major sound 14`
		makedev mixer      c $major  0 $audio
		makedev mixer1     c $major 16 $audio
		makedev mixer2     c $major 32 $audio
		makedev mixer3     c $major 48 $audio
		makedev sequencer  c $major  1 $audio
		makedev midi00     c $major  2 $audio
		makedev midi01     c $major 18 $audio
		makedev midi02     c $major 34 $audio
		makedev midi03     c $major 50 $audio
		makedev dsp        c $major  3 $audio
		makedev dsp1       c $major 19 $audio
		makedev dsp2       c $major 35 $audio
		makedev dsp3       c $major 51 $audio
		makedev audio      c $major  4 $audio
		makedev audio1     c $major 20 $audio
		makedev audio2     c $major 36 $audio
		makedev audio3     c $major 52 $audio
		makedev sndstat    c $major  6 $audio
		makedev audioctl   c $major  7 $audio
		major=31
		makedev mpu401data c $major 0  $audio
		makedev mpu401stat c $major 1  $audio
		major=35
		for i in 0 1 2 3
		do
			makedev midi$i  c $major $i $audio
			makedev rmidi$i c $major `math $i + 64` $audio
			makedev smpte$i c $major `math $i + 128` $audio
		done
		;;
	pcaudio)
		major=`Major pcsp 13` || continue
		makedev pcmixer c $major 0 $audio
		makedev pcsp    c $major 3 $audio
		makedev pcaudio c $major 4 $audio
		;;
	video|video4linux|v4l|radio)
		# video4linux api includes radio, teletext, etc.
		major=`Major video 81` || continue
		minor=0
		until [ $minor -gt 63 ]
		do
			makedev video$minor c $major $minor $video
			makedev radio$minor c $major `math $minor + 64` $video
			minor=`math $minor + 1`
		done
		symlink radio radio0
		minor=0
		until [ $minor -gt 31 ]
		do
			makedev vtx$minor c $major `math $minor + 192` $video
			makedev vbi$minor c $major `math $minor + 224` $video
			minor=`math $minor + 1`
		done
		symlink video video0
		symlink vbi vbi0
		major=82
		minor=0
		until [ $minor -gt 1 ]
		do
			makedev winradio$minor c $major $minor $video
			minor=`math $minor + 1`
		done
		major=83
		makedev vtx     c $major 0 $video
		makedev vttuner c $major 16 $video
		;;
	i2c)
		# making it possible to create an arbitrary number of i2c
		# devices might be good, but 8 should suffice for now
		major=`Major i2c 89` || continue
		minor=0
		until [ $minor -gt 7 ] 
		do
			makedev i2c-$minor c $major $minor $private
			minor=`math $minor + 1`
		done
		;;
	tlk)
		major=102
		minor=0
		until [ $minor -gt 3 ] # tell me if 3 is wrong...
		do
			makedev tlk$minor c $major $minor $video
			minor=`math $minor + 1`
		done
		;;
	srnd)
		makedev srnd0 c 110 0 $video
		makedev srnd1 c 110 1 $video
		;;
	fgrab)
		makedev mmetfgrab c 40 0 $video
		makedev wvisfgrab c 26 0 $video
		for i in 0 1 # more?
		do
			makedev iscc$i    c 93 $i $video
			makedev isccctl$i c 93 `math $i + 128` $video
		done
		for i in 0 1 # more?
		do
			makedev dcxx$i c 94 $i $video
		done
		;;
	sg|sg-all)
		major=`Major sg 21`
		for unit in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
		do
			makedev sg$unit c $major $unit $scsi
		done
		;;
	pg)
		major=`Major pg 97`
		for unit in 0 1 2 3
		do
			makedev pg$unit c $major $unit $scsi
		done
		;;
	fd)
		# not really devices, we use the /proc filesystem
		symlink fd     $procfs/self/fd
		symlink stdin  fd/0
		symlink stdout fd/1
		symlink stderr fd/2
		;;
	ibcs2)
		major=`Major ibcs2 30` || continue
		makedev socksys c $major 0 $ibcs2
		symlink nfsd socksys
		makedev spx     c $major 1 $ibcs2
		symlink X0R null
		;;
	netlink)
		major=36
		makedev route c $major 0 $private
		makedev skip  c $major 1 $private
		;;
	enskip)
		major=64
		makedev enskip c $major 0 $private
		;;
	ipfilt*)
		major=95
		makedev ipl     c $major 0 $private
		makedev ipnat   c $major 1 $private
		makedev ipstate c $major 2 $private
		makedev ipauth  c $major 3 $private
		;;
	qng)
		makedev qng c 77 0 $private
		;;
	apm)
		major=`Major mouse 10` || continue
		makedev apm_bios  c $major 134 $mouse
		;;
	dcf)
		major=`Major dcf` || continue
		makedev $arg c $major 0 $system
		;;
	helloworld)
		major=`Major hw` || continue
		makedev helloworld c $major 0 $public
		;;
	ipsec)
		# For the Free S/WAN (http://www.xs4all.nl/~freeswan/)
		# implementation of IPSEC
		makedev ipsec c 36 10 $ipsec
		;;
	comedi)
		major=98
		for minor in 0 1 2 3
		do
			makedev comedi$minor c $major $minor $public
		done
		;;
	tilp)
		for i in `seq 0 7`
		do
			makedev tipar$i c 115 $i $printer
			makedev tiser$i c 115 `math 8 + $i` $dialout
		done
		for i in `seq 0 31`
		do
			makedev tiusb$i c 115 `math 16 + $i` $dialout
		done
		;;
	dvb)
		# check if kernel-version is >= 2.6.8, if yes, create dvb-devices with
		# major-number 212, in the other case 250
		
		kern_rev1=`uname -r | sed -e 's@^\([^.]*\)\..*@\1@'`
		kern_rev2=`uname -r | sed -e 's@^[^.]*\.\([^.]*\)\..*@\1@'`
		kern_rev3=`uname -r | sed -e 's@^[^.]*\.[^.]*\.\([^.][0-9]*\).*@\1@'`
      
		dvb_major=250

		if [ $kern_rev1 -gt 2 ] || ([ $kern_rev1 -eq 2 ] && [ $kern_rev2 -gt 6 ]) \
			|| ([ $kern_rev1 -eq 2 ] && [ $kern_rev2 -eq 6 ] && [ $kern_rev3 -ge 8 ])
		then 
			dvb_major=212 
		fi

		mkdir -p dvb
		for i in 0 1 2 3
		do
			mkdir -p dvb/adapter$i
			makedev dvb/adapter$i/video0	c $dvb_major `math 64 \* $i + 0` $video
			makedev dvb/adapter$i/audio0    c $dvb_major `math 64 \* $i + 1` $video
			makedev dvb/adapter$i/frontend0 c $dvb_major `math 64 \* $i + 3` $video
			makedev dvb/adapter$i/demux0    c $dvb_major `math 64 \* $i + 4` $video
			makedev dvb/adapter$i/dvr0      c $dvb_major `math 64 \* $i + 5` $video
			makedev dvb/adapter$i/ca0       c $dvb_major `math 64 \* $i + 6` $video
			makedev dvb/adapter$i/net0      c $dvb_major `math 64 \* $i + 7` $video
			makedev dvb/adapter$i/osd0      c $dvb_major `math 64 \* $i + 8` $video
		done
		;;
	usb)
		mkdir -p usb
		major=180
		for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
		do
			makedev usb/lp$i c $major $i $printer
			makedev usb/mouse$i c $major `math $i + 16` $mouse
			makedev usb/ez$i c $major `math $i + 32` $system
			makedev usb/scanner$i c $major `math $i + 48` $scanner
			makedev usb/hiddev$i c $major `math $i + 96` $system
			makedev ttyACM$i c 166 $i $dialout
			makedev ttyUSB$i c 188 $i $dialout
		done
		makedev usb/rio500 c $major 64 $audio
		makedev usb/usblcd c $major 65 $audio
		makedev usb/cpad0 c $major 66 $audio
		;;
	bluetooth)
		major=216
		for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 \
			16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
		do
			makedev rfcomm$i c $major $i $dialout
		done
		makedev vhci c 10 250 $dialout
		for i in 0 1 2 3; do
			makedev ttyUB$i c 216 $i $dialout
			makedev ccub$i c 217 $i $dialout
		done
		;;
	paride)
                major=45
                for unit in a b c d
		do
                    base=`index abcd $unit`
                    base=`math $base \* 16`
                    makedev pd$unit b $major $base $disk
                    for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
                    do
			makedev pd$unit$part b $major $(( $base + $part )) $disk
                    done
		done
		for i in 0 1 2 3
		do
		    makedev pcd$i b 46 $i $cdrom
		    makedev pf$i  b 47 $i $floppy
		done
                ;;
        lirc)
                makedev lirc c 61 0 $lirc
                for i in d m; do
                   makefifo lirc${i} $lirc
                done
                ;;
	update)
		devices=
		if [ ! -f $procfs/devices ]
		then
			echo "$0: warning: can't read $procfs/devices" >&2
		else
			exec 3<$procfs/devices
			while read major device extra <&3
			do
				device=`echo $device | sed 's#/.*##'`
				case "$major" in
					Character|Block|'')
						;;
					*)
						eval "major_$device=$major"
						devices="$devices $device"
						;;
				esac
			done
			exec 3<&-
		fi

		if [ ! "$devices" ]
		then
			echo "$0: don't appear to have any devices" >&2
			continue
		fi
		if [ "$opt_d" ]
		then
			echo "$0: can't delete an update" >&2
			continue
		fi
		create=
		delete=
		devs="$devices"
		if [ -f DEVICES ]
		then
			exec 3<DEVICES
			while read device major <&3
			do
				eval now=\$major_$device
				if [ "$now" = "" ]
				then
					delete="$delete `cvt $device`"
					continue
				elif [ "$now" != $major ]
				then
					create="$create "`cvt $device`
				fi
				devs=`strip " $devs " $device`
			done
			exec 3<&-
		fi
		create="$create "`cvt $devs`
		[ "$delete" != "" ] && $0 $opts -d $delete
		[ "$create" != " " ] && $0 $opts $create
		[ "$opt_n" ] && continue
		for device in $devices
		do
			if [ "`cvt $device`" ]
			then
			    eval echo $device \$major_$device
			fi
		done > DEVICES
		;;
	*)
		echo "$0: don't know how to make device \"$arg\"" >&2
		exit 1
		;;
	esac
done

exit 0
