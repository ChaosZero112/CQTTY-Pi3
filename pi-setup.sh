#!/bin/bash
#Pi Setup script
#Created by Cody Lusk (clusk@aizan.com)
#with parts from MyConnection Server (Visualware, Inc.)
#and various StackOverflow community responses.
#
#This script will acomplish the following tasks:
#
# Enable SSH
# Enable Boot Splash
# Disable local login (disable getty)
# Setup user (pi) password
# Modify cmdline.txt to show splash, disable logos and hide verbose
# Install the Remote Agent (RTA)
# Create an RTA service and enable it
# Disable Bluetooth and WiFi (and disable hciuart service)
#
#The use of this script is at the risk of the user.
#There is a change this will mess up the Raspberry Pi,
#requiring a system restore or flash.
#Aizan Technologies Inc, it's employees, and Cody Lusk take
#no responsibility for any damages caused by this script or
#the RTA application.
#No warranty is expressed or implied.
#Built on 2017-08-15

#Script colours
#Thanks to k-five (https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux)
RCol='\e[0m'    # Text Reset

# Regular           Bold                Underline           High Intensity      BoldHigh Intens     Background          High Intensity Backgrounds
Bla='\e[0;30m';     BBla='\e[1;30m';    UBla='\e[4;30m';    IBla='\e[0;90m';    BIBla='\e[1;90m';   On_Bla='\e[40m';    On_IBla='\e[0;100m';
Red='\e[0;31m';     BRed='\e[1;31m';    URed='\e[4;31m';    IRed='\e[0;91m';    BIRed='\e[1;91m';   On_Red='\e[41m';    On_IRed='\e[0;101m';
Gre='\e[0;32m';     BGre='\e[1;32m';    UGre='\e[4;32m';    IGre='\e[0;92m';    BIGre='\e[1;92m';   On_Gre='\e[42m';    On_IGre='\e[0;102m';
Yel='\e[0;33m';     BYel='\e[1;33m';    UYel='\e[4;33m';    IYel='\e[0;93m';    BIYel='\e[1;93m';   On_Yel='\e[43m';    On_IYel='\e[0;103m';
Blu='\e[0;34m';     BBlu='\e[1;34m';    UBlu='\e[4;34m';    IBlu='\e[0;94m';    BIBlu='\e[1;94m';   On_Blu='\e[44m';    On_IBlu='\e[0;104m';
Pur='\e[0;35m';     BPur='\e[1;35m';    UPur='\e[4;35m';    IPur='\e[0;95m';    BIPur='\e[1;95m';   On_Pur='\e[45m';    On_IPur='\e[0;105m';
Cya='\e[0;36m';     BCya='\e[1;36m';    UCya='\e[4;36m';    ICya='\e[0;96m';    BICya='\e[1;96m';   On_Cya='\e[46m';    On_ICya='\e[0;106m';
Whi='\e[0;37m';     BWhi='\e[1;37m';    UWhi='\e[4;37m';    IWhi='\e[0;97m';    BIWhi='\e[1;97m';   On_Whi='\e[47m';    On_IWhi='\e[0;107m';

clear
cd /tmp/
clear

# Introduction message
echo
echo -e "${Red}=========================================================${RCol}"
echo
echo -e "Welcome to the ${Yel}CQTTy-Pi3${RCol} Setup Script."
echo
echo "This script will convert a Raspberry Pi into a CQTTy-Pi3."
echo
echo "To begin, Dialog will be installed if it's not found."
echo
echo -e "${Red}=========================================================${RCol}"
echo
read -p "Press enter to continue"

# Check for root or Sudo

ROOT_UID="0"

#Check if run as root
if [ "$UID" -ne "$ROOT_UID" ] ; then
	clear
	echo
	echo -e "== ${IRed}WARNING ${IYel}WARNING ${IWhi}WARNING ${RCol}=="
	echo
	echo "You must be root to run this script."
	echo
	echo -e "Run command ${Gre}sudo ./pi-setup.sh${RCol}"
	echo
	echo "Exiting..."
	echo
	echo -e "== ${ICya}WARNING ${IGre}WARNING ${IPur}WARNING ${RCol}=="
	echo
	exit 1
fi

#Installing Dialog if needed
if ! type "dialog" > /dev/null; then
	apt-get update && apt-get install -y dialog
fi

ReplacePassword=password
HEIGHT=15
WIDTH=60
CHOICE_HEIGHT=4
BACKTITLE="CQTTY-Pi3 Setup"

if [ "`systemctl is-enabled ssh`" != "enabled" ] 
then 
	dialog --title "SSH" \
			--backtitle "$BACKTITLE" \
			--yesno "
			We noticed that SSH may not currently be enabled.
			
			We highly recommend enabling it before going forward as this script has the ability to disable local login, making SSH the only available option to access the device.
			
			Tip: It will also make adding rta.exe easier (via SFTP), a required step in the setup.
			
			Would you like to enable SSH? (a reboot will be required)
			" 20 $WIDTH

response=$?
	case $response in
	0) touch /boot/SSH && systemctl enable ssh && reboot;;
	1) ;;
	255) echo "[ESC] key pressed."; exit;;
	esac
fi

OPTIONS=(1 "Run Automated Setup"
         2 "Allow local login"
         3 "Run Raspbian config"
		 4 "Quit")

CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "Menu" \
                --menu "Choose one of the following options:" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
        1)
            if [ ! -d "/tmp/RTA" ]; then
			mkdir -m 777 -p /tmp/RTA
			fi
			chmod 777 /tmp/RTA
			clear
			dialog --title "rta.exe" \
			--backtitle "CQTTY-Pi3 Setup" \
			--yesno "
			We need rta.exe from speedtest.aizan.com.
			
			Please place rta.exe in /tmp/RTA/ before continuing.
			
			Did you place rta.exe in the RTA folder?
			" $HEIGHT $WIDTH

response=$?
case $response in
   0) echo;;
   1) dialog --title "rta.exe" \
				--backtitle "$BACKTITLE" \
				--msgbox "
				Put rta.exe in /tmp/RTA/ and run this script again." $HEIGHT $WIDTH; clear; exit;;
   255) echo "[ESC] key pressed."; exit;;
esac

			if [ ! -e "/tmp/RTA/rta.exe" ]; then
				dialog --title "rta.exe" \
				--backtitle "$BACKTITLE" \
				--msgbox "Not so fast...
				
				Could not find rta.exe in /tmp/RTA/
				
				Put rta.exe in /tmp/RTA/ and run this script again." $HEIGHT $WIDTH
				clear
				exit
			fi

(			if [ -d "/etc/RTA" ]; then
			rm -rf /etc/RTA
			fi
						if ! type "java" > /dev/null; then
			apt-get install -y default-jre
			fi
			
			# This is a modified version of the MyConnection installation script.
			# Now the heavy lifting starts.
			# Hold on to your butts...
			#                                                  ~ (@)  ~~~---_
			#                                               {     `-_~,,,,,,)
			#                                               {    (_  ',
			#                                                ~    . = _',
			#                                                 ~    '.  =-'
			#                                                   ~     :
			#.                                                -~     ('');
			#'.                                         --~        \  \ ;
			#  '.-_                                   -~            \  \;      _-=,.
			#     -~- _                          -~                 {  '---- _'-=,.
 			#      ~- _~-  _              _ -~                     ~---------=,.`
			#            ~-  ~~-----~~~~~~       .+++~~~~~~~~-__   /
			#                ~-   __            {   -     +   }   /
			#                         ~- ______{_    _ -=\ / /_ ~
			#                             :      ~--~    // /         ..-
			#                             :   / /      // /         ((
			#                             :  / /      {   `-------,. ))
			#                             :   /        ''=--------. }o
			#                .=._________,'  )                     ))
			#                )  _________ -''                     ~~
			#               / /  _ _
			#              (_.-.'O'-'.
			
			mkdir -m 775 -p /etc/RTA
			mv /tmp/RTA/rta.exe /etc/RTA/rta.exe
			chmod 777 /etc/RTA/rta.exe
			cd /etc/RTA/
			wget -q -N "http://speedtest.aizan.com/myspeed/unixrta.tar"
			tar -xf unixrta.tar
			platform=`uname -s`;
			cdir=`pwd`;
			mdir="/etc/RTA";
if [ -f $mdir/rta.sh ]; then
	sh $mdir/rta.sh stop;
fi
if [ ! -d $mdir ]; then
	mkdir -m 775 -p $mdir;
fi

if [ -f libmswin32v15.jnilib ]; then
       	rm libmswin32v15.jnilib;
fi
if [ -f libmswin32v15-linux-32bit.so ]; then
       	rm libmswin32v15-linux-32bit.so;
fi
if [ -f libmswin32v15-linux-64bit.so ]; then
       	rm libmswin32v15-linux-64bit.so;
fi
if [ -f libmswin32v15-freebsd-32bit.so ]; then
       	rm libmswin32v15-freebsd-32bit.so;
fi
if [ -f libmswin32v15-freebsd-64bit.so ]; then
       	rm libmswin32v15-freebsd-64bit.so;
fi
if [ -f libmswin32v15-solaris.so ]; then
       	rm libmswin32v15-solaris.so;
fi

bnam=`basename $mdir`;
cd $mdir;
dat=`date +%a%M%S`;
rm -rf *.jar;
tar -xf $cdir/rta.tar;
mv rta.jar $dat-rta.jar;
fdir=`pwd`;

if [ "$platform" = 'FreeBSD' ]; then
	dirlist="/usr/local";
elif [ -d /opt ]; then
	dirlist="/usr /opt";
else
	dirlist="/usr";
fi

if [ "$platform" = 'Darwin' ]; then
	find -H $dirlist -name java -print > /tmp/java.$$;
else
	find $dirlist -type f -name java -print > /tmp/java.$$;
fi

if [ ! -s /tmp/java.$$ ]; then
	echo "MyConnection Server Remote Agent requires a Java VM, but was unable to";
	echo "find one installed.";
	echo " ";
	echo "Please visit http://java.sun.com to download and install a free one.";
	echo "After you have installed a JVM, try this script again with:-";
	echo "'sh $cdir/rta_configure.sh'";
	echo "  for further information please review readme.txt.";
	exit 1;
fi

dirnam="";
jconfirm="";
for i in `cat /tmp/java.$$`
do
	fulljvm=`$i -classpath . TestJVM`;
	testjvm=`$i -classpath . TestJVM 2>/dev/null | awk '{ print $1 }'`;
	if [ "$testjvm" = "Correct" ]; then
		testversion=`$i -classpath . TestJVM 2>/dev/null | awk '{ print $2 }'`;
		echo "$testversion $i" >> /tmp/javaversion.$$;
	fi
	
done

if [ -f /tmp/java.$$ ]; then 
	rm /tmp/java.$$;
fi

if [ ! -s /tmp/javaversion.$$ ]; then
	echo "=========================================="
	echo "MyConnection Server Remote Agent is only supported with the Sun or IBM JVM.";
	echo " ";
	echo "Please visit http://java.sun.com to download and install a Sun JVM.";
	echo "After you have installed the Sun JVM, try this script again.";
	echo "This script will search for the JVM in the /usr and /opt directories.";
	echo " ";
	exit 1;
 else
	jconfirm=`sort -r /tmp/javaversion.$$ | head -n 1 | awk '{ print $2 }'`
	dirnam=`dirname $jconfirm`;
	echo "$dirnam is to be used";
fi

if [ -f /tmp/javaversion.$$ ]; then 
	rm /tmp/javaversion.$$;
fi

if [ -f start_rta.sh ]; then 
	rm start_rta.sh;
fi
echo "#!/bin/sh" > start_rta.sh;
echo " " >> start_rta.sh;
echo ": Make sure we get executed by sh on all systems" >> start_rta.sh;
echo "sh $fdir/rta.sh start" >> start_rta.sh;
chmod +x start_rta.sh;

if [ -f stop_rta.sh ]; then 
	rm stop_rta.sh;
fi
echo "#!/bin/sh" > stop_rta.sh;
echo " " >> stop_rta.sh;
echo ": Make sure we get executed by sh on all systems" >> stop_rta.sh;
echo "sh $fdir/rta.sh stop" >> stop_rta.sh;
chmod +x stop_rta.sh;

if [ -f rta.sh ]; then 
	rm rta.sh;
fi

echo "#!/bin/sh" > rta.sh;
echo "# " >> rta.sh;
echo "# $bnam	This shell script starts and stops $bnam" >> rta.sh;
echo "# chkconfig: 2345 85 10" >> rta.sh;
echo "# description: MyConnection Server Remote Agent agent performs network tests" >> rta.sh;
echo " " >> rta.sh;
echo ": Make sure we get executed by sh on all systems" >> rta.sh;
echo " " >> rta.sh;
echo "MSHOME=/etc/RTA/" >> rta.sh;
echo "PATH=${dirnam}:/usr/bin:/bin:$fdir:." >> rta.sh;
echo "export MSHOME PATH" >> rta.sh;
cat PartTwo.sh >> rta.sh;
cd /etc/RTA/
rm PartTwo.sh rta.tar;
chmod +x rta.sh;
cd /tmp/) | dialog --title "RTA Setup" \
				--backtitle "$BACKTITLE" \
				--progressbox "Now installing the RTA Agent. Please wait..." $HEIGHT $WIDTH

(			echo "Changing hostname to CQTTy-Pi3"
			sed -i -e 's/raspberrypi/CQTTyPi3/g' /etc/hosts
			sed -i -e 's/raspberrypi/CQTTyPi3/g' /etc/hostname
			sh /etc/init.d/hostname.sh
			echo "Changing keyboard to US-en"
			sed -i -e 's/gb/us/g' /etc/default/keyboard
			echo "Enabling CLI boot."
			systemctl set-default multi-user.target
			echo "Disabling tty login."
			systemctl disable getty@tty1.service
			systemctl disable getty@tty2.service
			systemctl disable getty@tty3.service
			systemctl disable getty@tty4.service
			echo "Setting boot options."
			sed -i -e 's/tty1/tty3/g' /boot/cmdline.txt
			sed -i -e 's/rootwait/rootwait loglevel=0 vt.global_cursor_default=0 splash quiet logo.nologo plymouth.ignore-serial-consoles/g' /boot/cmdline.txt
			sed -i -e 's/#disable_overscan/disable_overscan/g' /boot/config.txt
			echo "Creating RTA service."
			if [ -e /etc/systemd/system/RemoteAgent.service ]
			then
				echo "RTA Service already exits."
			else
				cat > /etc/systemd/system/RemoteAgent.service << EOF
[Unit]
Description=CQTTy-Pi3 Remote Agent
Documentation=http://userguide.cqtty-pi.com/
After=network.target

[Service]
Type=forking
ExecStart=/etc/RTA/rta.sh start
ExecStop=/etc/RTA/rta.sh stop
ExecStatus=/etc/RTA/rta.sh status
Restart=always
RestartSec=60s

[Install]
WantedBy=multi-user.target
Alias=RTA
EOF
			fi
			systemctl daemon-reload
			systemctl enable RemoteAgent.service
			systemctl start RemoteAgent.service
			echo "Disabling Bluetooth and WiFi."
			if [ -e /etc/modprobe.d/raspi-blacklist.conf ]
			then
				rm /etc/modprobe.d/raspi-blacklist.conf
			fi
				cat > /etc/modprobe.d/raspi-blacklist.conf << EOF
#wifi
blacklist brcmfmac
blacklist brcmutil
#bt
blacklist btbcm
blacklist hci_uart
EOF
			systemctl disable hciuart
			echo "Setting up plymouth."
			if [ ! -d "/usr/share/plymouth/themes/simple/" ]; then
			mkdir /usr/share/plymouth/themes/simple
			else
			rm -rf /usr/share/plymouth/themes/simple
			mkdir /usr/share/plymouth/themes/simple
			fi
			cat > /usr/share/plymouth/themes/simple/simple.plymouth << EOF
[Plymouth Theme]
Name=Simple
Description=Wallpaper only
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/simple
ScriptFile=/usr/share/plymouth/themes/simple/simple.script
EOF
			
			cat > /usr/share/plymouth/themes/simple/simple.script << EOF
wallpaper_image = Image("wallpaper.png");
screen_width = Window.GetWidth();
screen_height = Window.GetHeight();
resized_wallpaper_image = wallpaper_image.Scale(screen_width,screen_height);
wallpaper_sprite = Sprite(resized_wallpaper_image);
wallpaper_sprite.SetZ(-100);
EOF
			wget -q "https://drive.google.com/uc?export=download&id=0BzyibqsH_3b2TjZDeFRhTEtBM1k"
			mv uc\?export\=download\&id\=0BzyibqsH_3b2TjZDeFRhTEtBM1k  /usr/share/plymouth/themes/simple/wallpaper.png
			update-initramfs -u
			plymouth-set-default-theme simple)  | dialog --title "System Customizations" \
				--backtitle "$BACKTITLE" \
				--progressbox "Making some modifications..." $HEIGHT $WIDTH
			echo
			(apt-get upgrade -y) | dialog --title "Cleaning up" \
				--backtitle "$BACKTITLE" \
				--progressbox "Almost done... Doing updates and housecleaning." $HEIGHT $WIDTH
			cd /tmp/
			rm -rf /tmp/RTA/
			clear
			#Set password
			echo "pi:$ReplacePassword" | chpasswd
			clear
			dialog --title "Done" \
				--backtitle "$BACKTITLE" \
				--msgbox "All done. The system will now reboot.
				
				After the system boots, check speedtest.aizan.com to ensure CQTTY-Pi3 registered." $HEIGHT $WIDTH
			reboot
            ;;
        2)
			systemctl enable getty@tty1.service
			systemctl enable getty@tty2.service
			systemctl enable getty@tty3.service
			systemctl enable getty@tty4.service
			reboot
			exit
            ;;
        3)
			raspi-config
			exit
			;;
		4)
            echo "Bye!"
			echo
			exit
            ;;
esac
