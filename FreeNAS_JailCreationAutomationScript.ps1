<###############################################################################
################################################################################
Freenas Jail Automation

TheRealShadoh
################################################################################
################################################################################

Generates a directory of configuration files for Plex, Tautulli, Radarr, Sonarr,
Transmission, SABnzbd, Nzbhydra2, Lidarr.

Currently requires manual copy/paste from the configuration files, as well as
manually entering the rc.d files from the configuration files. Some basic
steps are included within the configuration files for these parts.

The goal is to implement SSH into the powershell script which will allow the script
to create configuration files, and implement the configuration changes. Decreasing 
the amount of steps needed to be accomplished on the FreeNAS GUI to pre-stage the
environment for the jails.

Limitations
Only supports a single storage pool configuration.

Requirements

1. Storage pool created
2. SSH enabled
3. SSH account available (root is disabled by default)
4. Creation of datasets for
    - downloads
        --sabnzbd
        --torrents
    -media
        --movies
        --tv
        --anime
        --music
    -appdata
5. Creation of media user on FreeNAS with a known UID
6. Creation of media group on FreeNAS with a known UID
7. Assign the user and group created above (media) as the owner of the datasets.

Untested as of yet from a clean configuration. Spot tested wit 11.1 and 11.2

I'm not a FreeNAS guru so if you see any issues or better ways to do things, don't hesitate! 
#>

# Host Config
$hostIP = "PLACEHOLDER"
$hostUsername = "PLACEHOLDER"
$hostPassword = "PLACEHOLDER"
$storage1 = "ShadohNAS" #Enter the name of your storage pool
$storage2 = "ShadohSSD" #Enter the name of an additional storage pool
$jailRelease = "11.2-RELEASE"
$sharedAccountName = "media"
$sharedAccountUID = "8675309"

# Jail Config
# Plex
$jailPlexName = "plex"
$jailPlexIP4 = "192.168.1.9"
$jailPlexVnet = "vnet0|"
$jailPlexCIDR = "/24"
$jailPlexGateway = "192.168.1.1"
# Tautuli
$jailTautulliName = "tautulli"
$jailTautulliIP4 = "192.168.1.8"
$jailTautulliVnet = "vnet0|"
$jailTautulliCIDR = "/24"
$jailTautulliGateway = "192.168.1.1"
# Radarr
$jailRadarrName = "radarr"
$jailRadarrIP4 = "192.168.1.6"
$jailRadarrVnet = "vnet0|"
$jailRadarrCIDR = "/24"
$jailRadarrGateway = "192.168.1.1"
# Sonarr
$jailSonarrName = "sonarr"
$jailSonarrIP4 = "192.168.1.7"
$jailSonarrVnet = "vnet0|"
$jailSonarrCIDR = "/24"
$jailSonarrGateway = "192.168.1.1"
# Transmission
$jailTransmissionName = "transmission"
$jailTransmissionIP4 = "192.168.1.11"
$jailTransmissionVnet = "vnet0|"
$jailTransmissionCIDR = "/24"
$jailTransmissionGateway = "192.168.1.1"
# Sabnzbd
$jailSabName = "sabnzbd"
$jailSabIP4 = "192.168.1.10"
$jailSabVnet = "lagg0|"
$jailSabCIDR = "/24"
$jailSabGateway = "192.168.1.1"
# Hydra
$jailHydraName = "hydra"
$jailHydraIP4 = "192.168.1.12"
$jailHydraVnet = "vnet0|"
$jailHydraCIDR = "/24"
$jailHydraGateway = "192.168.1.1"
# Lidarr
$jailLidarrName = "lidarr"
$jailLidarrIP4 = "192.168.1.14"
$jailLidarrVnet = "vnet0|"
$jailLidarrCIDR = "/24"
$jailLidarrGateway = "192.168.1.1"

#region DO NOT MODIFY THIS REGION
#region Plex
    #Localize variables
    $jailname = $jailPlexName
    $jailIP4 = $jailPlexIP4
    $jailVnet = $jailPlexVnet
    $jailCIDR = $jailPlexCIDR
    $jailGateway = $jailPlexGateway

$plexConfig = @"
#Initialize jail
echo '{"pkgs":["plexmediaserver-plexpass","ca_root_nss"]}' > /tmp/pkg.json
iocage create -n "$($jailname)" -p /tmp/pkg.json -r "$($jailRelease)" ip4_addr="$($jailVnet)$($jailIP4)$($jailCIDR)" defaultrouter="$($jailGateway)" vnet="on" allow_raw_sockets="1" boot="on" 
rm /tmp/pkg.json
mkdir /mnt/$($storage1)/appdata/$($jailname)
#Mount storage
iocage fstab -a $jailname /mnt/$($storage1)/appdata/$($jailname) /config nullfs rw 0 0
iocage fstab -a $jailname /mnt/$($storage1)/media/movies /mnt/movies nullfs ro 0 0
iocage fstab -a $jailname /mnt/$($storage1)/media/tv /mnt/tv nullfs ro 0 0
iocage fstab -a $jailname /mnt/$($storage1)/media/music /mnt/music nullfs ro 0 0
iocage fstab -a $jailname /mnt/$($storage1)/media/anime /mnt/anime nullfs ro 0 0
#Configure jail
iocage exec $jailname "pw user add $($sharedAccountName) -c $($sharedAccountName) -u $($sharedAccountUID) -d /nonexistent -s /usr/bin/nologin"
iocage exec $jailname "chown -R $($sharedAccountName):$($sharedAccountName) /config"
iocage exec $jailname sysrc "plexmediaserver_plexpass_enable=YES"
iocage exec $jailname sysrc plexmediaserver_plexpass_support_path="/config"
iocage exec $jailname sysrc plexmediaserver_plexpass_support_user="$($sharedAccountName)"
iocage exec $jailname sysrc plexmediaserver_plexpass_support_group="$($sharedAccountName)"
iocage exec $jailname service plexmediaserver_plexpass start
iocage exec $jailname "mkdir -p /usr/local/etc/pkg/repos"
iocage exec $jailname ee "/usr/local/etc/pkg/repos/FreeBSD.conf"
#Manual steps
# Make FreeBSD.conf look like the below section. Ctrl+C then type exit to save. 
FreeBSD: {
    url: "pkg+http://pkg.FreeBSD.org/${ABI}/latest"
}
# Plex location 
Plex should then be avaible at "http://$($jailIP4)/web"
"@
#endregion 
#region Tautulli
    #Localize variables
    $jailname = $jailTautulliName
    $jailIP4 = $jailTautulliIP4
    $jailVnet = $jailTautulliVnet
    $jailCIDR = $jailTautulliCIDR
    $jailGateway = $jailTautulliGateway
$tautulliConfig = @"
#Initialize jail
echo '{"pkgs":["python2","py27-sqlite3","py27-openssl","ca_root_nss","git"]}' > /tmp/pkg.json
iocage create -n "$($jailname)" -p /tmp/pkg.json -r "$($jailRelease)" ip4_addr="$($jailVnet)$($jailIP4)$($jailCIDR)" defaultrouter="$($jailGateway)" vnet="on" allow_raw_sockets="1" boot="on" 
rm /tmp/pkg.json
mkdir /mnt/$($storage1)/appdata/$($jailname)
#Mount storage
iocage fstab -a $jailname /mnt/$($storage1)/appdata/$($jailname) /config nullfs rw 0 0
#Confifure jail
iocage exec $jailname "pw user add $($sharedAccountName) -c $($sharedAccountName) -u $($sharedAccountUID) -d /nonexistent -s /usr/bin/nologin"
iocage exec $jailname git clone https://github.com/Tautulli/Tautulli.git /usr/local/share/tautulli
iocage exec $jailname "chown -R $($sharedAccountName):$($sharedAccountName) /usr/local/share/tautulli /config"
iocage exec $jailname cp /usr/local/share/Tautulli/init-scripts/init.freenas /usr/local/etc/rc.d/tautulli
iocage exec $jailname chmod u+x /usr/local/etc/rc.d/tautulli
iocage exec $jailname sysrc "tautulli_enable=YES"
iocage exec $jailname sysrc "tautulli_flags=--datadir /config"
iocage exec $jailname sysrc "tautulli_user=$($SharedAccountName)"
iocage exec $jailname sysrc "tautulli_group=$($SharedAccountName)"
iocage exec $jailname service tautulli start

## Tautulli location
Tautulli should then be available at http://$($jailIP4):8181
"@
#endregion

#region Radarr
    #Localize variables
    $jailname = $jailRadarrName
    $jailIP4 = $jailRadarrIP4
    $jailVnet = $jailRadarrVnet
    $jailCIDR = $jailRadarrCIDR
    $jailGateway = $jailRadarrGateway
$radarrConfig = @"
#Initialize jail
echo '{"pkgs":["mono","mediainfo","sqlite3","ca_root_nss","curl"]}' > /tmp/pkg.json
iocage create -n "$($jailname)" -p /tmp/pkg.json -r "$($jailRelease)" ip4_addr="$($jailVnet)$($jailIP4)$($jailCIDR)" defaultrouter="$($jailGateway)" vnet="on" allow_raw_sockets="1" boot="on" 
rm /tmp/pkg.json
mkdir /mnt/$($storage1)/appdata/$($jailname)
mkdir /mnt/$($storage1)/downloads/torrents
mkdir /mnt/$($storage1)/downloads/torrents/completed    
mkdir /mnt/$($storage1)/downloads/sabnzbd
mkdir /mnt/$($storage1)/downloads/sabnzbd/movies
mkdir /mnt/$($storage1)/media
mkdir /mnt/$($storage1)/media/movies
#Mount storage
iocage fstab -a $jailname /mnt/$($storage1)/appdata/$($jailname) /config nullfs rw 0 0
iocage fstab -a $jailname /mnt/$($storage1)/downloads/torrents/completed /mnt/torrents nullfs rw 0 0
iocage fstab -a $jailname /mnt/$($storage1)/downloads/sabnzbd/movies /mnt/nzbd nullfs rw 0 0
iocage fstab -a $jailname /mnt/$($storage1)/media/movies /mnt/movies nullfs rw 0 0
#Configure jail
iocage exec $jailname ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec $jailname "fetch https://github.com/Radarr/Radarr/releases/download/v0.2.0.995/Radarr.develop.0.2.0.995.linux.tar.gz -o /usr/local/share"
iocage exec $jailname "tar -xzvf /usr/local/share/Radarr.*.linux.tar.gz -C /usr/local/share"
iocage exec $jailname rm /usr/local/share/Radarr.*.linux.tar.gz
iocage exec $jailname "pw user add $($sharedAccountName) -c $($sharedAccountName) -u $($sharedAccountUID) -d /nonexistent -s /usr/bin/nologin"
iocage exec $jailname "chown -R $($sharedAccountName):$($sharedAccountName) /usr/local/share/Radarr /config"
iocage exec $jailname mkdir /usr/local/etc/rc.d
#Manual steps
iocage exec $jailname ee "/usr/local/etc/rc.d/radarr"
    #!/bin/sh

    # $FreeBSD$
    #
    # PROVIDE: radarr
    # REQUIRE: LOGIN
    # KEYWORD: shutdown
    #
    # Add the following lines to /etc/rc.conf.local or /etc/rc.conf
    # to enable this service:
    #
    # radarr_enable:    Set to YES to enable radarr
    #            Default: NO
    # radarr_user:    The user account used to run the radarr daemon.
    #            This is optional, however do not specifically set this to an
    #            empty string as this will cause the daemon to run as root.
    #            Default: media
    # radarr_group:    The group account used to run the radarr daemon.
    #            This is optional, however do not specifically set this to an
    #            empty string as this will cause the daemon to run with group wheel.
    #            Default: media
    # radarr_data_dir:    Directory where radarr configuration
    #            data is stored.
    #            Default: /var/db/radarr

    . /etc/rc.subr
    name=radarr
    rcvar=${name}_enable
    load_rc_config $name

    : ${radarr_enable:="NO"}
    : ${radarr_user:="$($sharedAccountName)"}
    : ${radarr_group:="$($sharedAccountName)"}
    : ${radarr_data_dir:="/config"}

    pidfile="${radarr_data_dir}/nzbdrone.pid"
    command="/usr/sbin/daemon"
    procname="/usr/local/bin/mono"
    command_args="-f ${procname} /usr/local/share/Radarr/Radarr.exe --data=${radarr_data_dir} --nobrowser"

    start_precmd=radarr_precmd
    radarr_precmd() {
        if [ ! -d ${radarr_data_dir} ]; then
        install -d -o ${radarr_user} -g ${radarr_group} ${radarr_data_dir}
        fi

        export XDG_CONFIG_HOME=${radarr_data_dir}
    }

    run_rc_command "$1"

#Configure jail part 2
iocage exec $jailname chmod u+x /usr/local/etc/rc.d/radarr
iocage exec $jailname sysrc "radarr_enable=YES"
iocage exec $jailname sysrc "radarr_user=$($sharedAccountName)"
iocage exec $jailname sysrc "radarr_group=$($sharedAccountName)"
iocage exec $jailname service radarr start

## Radarr location
Radarr should be available at http://$($jailIP4):7878
"@
#endregion

#region Sonarr
    #Localize variables
    $jailname = $jailSonarrName
    $jailIP4 = $jailSonarrIP4
    $jailVnet = $jailSonarrVnet
    $jailCIDR = $jailSonarrCIDR
    $jailGateway = $jailSonarrGateway
$sonarrConfig = @"
#Initialize jail
echo '{"pkgs":["mono","mediainfo","sqlite3","ca_root_nss","curl"]}' > /tmp/pkg.json
iocage create -n "$($jailname)" -p /tmp/pkg.json -r "$($jailRelease)" ip4_addr="$($jailVnet)$($jailIP4)$($jailCIDR)" defaultrouter="$($jailGateway)" vnet="on" allow_raw_sockets="1" boot="on" 
rm /tmp/pkg.json
mkdir /mnt/$($storage1)/appdata/$($jailname)
mkdir /mnt/$($storage1)/downloads/torrents
mkdir /mnt/$($storage1)/downloads/torrents/completed    
mkdir /mnt/$($storage1)/downloads/sabnzbd
mkdir /mnt/$($storage1)/downloads/sabnzbd/tv
mkdir /mnt/$($storage1)/media
mkdir /mnt/$($storage1)/media/tv
#Mount storage
iocage fstab -a $jailname /mnt/$($storage1)/appdata/$($jailname) /config nullfs rw 0 0
iocage fstab -a $jailname /mnt/$($storage1)/downloads/torrents/completed /mnt/torrents nullfs rw 0 0
iocage fstab -a $jailname /mnt/$($storage1)/downloads/sabnzbd/tv /mnt/nzbd nullfs rw 0 0
iocage fstab -a $jailname /mnt/$($storage1)/media/tv /mnt/tv nullfs rw 0 0
iocage fstab -a $jailname /mnt/$($storage1)/media/anime /mnt/anime nullfs rw 0 0
#Configure jail
iocage exec $jailname ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec $jailname "fetch http://download.sonarr.tv/v2/master/mono/NzbDrone.master.tar.gz -o /usr/local/share"
iocage exec $jailname "tar -xzvf /usr/local/share/NzbDrone.master.tar.gz -C /usr/local/share"
iocage exec $jailname rm /usr/local/share/NzbDrone.master.tar.gz
iocage exec $jailname "pw user add $($sharedAccountName) -c $($sharedAccountName) -u $($sharedAccountUID) /nonexistent -s /usr/bin/nologin"
iocage exec $jailname chown -R $($sharedAccountName):$($sharedAccountName) /usr/local/share/NzbDrone /config
iocage exec $jailname mkdir /usr/local/etc/rc.d
iocage exec $jailname ee "/usr/local/etc/rc.d/sonarr"
#Manual Steps
#!/bin/sh

# $FreeBSD$
#
# PROVIDE: sonarr
# REQUIRE: LOGIN
# KEYWORD: shutdown
#
# Add the following lines to /etc/rc.conf.local or /etc/rc.conf
# to enable this service:
#
# sonarr_enable:    Set to YES to enable sonarr
#            Default: NO
# sonarr_user:    The user account used to run the sonarr daemon.
#            This is optional, however do not specifically set this to an
#            empty string as this will cause the daemon to run as root.
#            Default: media
# sonarr_group:    The group account used to run the sonarr daemon.
#            This is optional, however do not specifically set this to an
#            empty string as this will cause the daemon to run with group wheel.
#            Default: media
# sonarr_data_dir:    Directory where sonarr configuration
#            data is stored.
#            Default: /var/db/sonarr

. /etc/rc.subr
name=sonarr
rcvar=${name}_enable
load_rc_config $name

: ${sonarr_enable:="NO"}
: ${sonarr_user:="$($sharedAccountName"}
: ${sonarr_group:="$($sharedAccountName"}
: ${sonarr_data_dir:="/config"}

pidfile="${sonarr_data_dir}/nzbdrone.pid"
command="/usr/sbin/daemon"
procname="/usr/local/bin/mono"
command_args="-f ${procname} /usr/local/share/NzbDrone/NzbDrone.exe --data=${sonarr_data_dir} --nobrowser"

start_precmd=sonarr_precmd
sonarr_precmd() {
    if [ ! -d ${sonarr_data_dir} ]; then
    install -d -o ${sonarr_user} -g ${sonarr_group} ${sonarr_data_dir}
    fi

    export XDG_CONFIG_HOME=${sonarr_data_dir}
}

run_rc_command "$1"

#Configure jail part 2
iocage exec $jailname chmod u+x /usr/local/etc/rc.d/sonarr
iocage exec $jailname sysrc "sonarr_enable=YES"
iocage exec $jailname sysrc "sonarr_user=$($sharedAccountName)"
iocage exec $jailname sysrc "sonarr_group=$($sharedAccountName)"
iocage exec $jailname service sonarr start

## Sonarr location
http://192.168.1.7:8989
"@
#endregion

#region Transmission
    #Localize variables
    $jailname = $jailTransmissionName
    $jailIP4 = $jailTransmissionIP4
    $jailVnet = $jailTransmissionVnet
    $jailCIDR = $jailTransmissionCIDR
    $jailGateway = $jailTransmissionGateway

$transmissionConfig = @"
#Initialize jail
echo '{"pkgs":["transmission","ca_root_nss"]}' > /tmp/pkg.json
iocage create -n "$($jailname)" -p /tmp/pkg.json -r "$($jailRelease)" ip4_addr="$($jailVnet)$($jailIP4)$($jailCIDR)" defaultrouter="$($jailGateway)" vnet="on" allow_raw_sockets="1" boot="on" 
rm /tmp/pkg.json
mkdir /mnt/$($storage1)/appdata/$($jailname)
mkdir /mnt/$($storage1)/downloads/torrents/completed    
#Mount storage
iocage fstab -a $jailname /mnt/$($storage1)/appdata/$($jailname) /config nullfs rw 0 0
iocage fstab -a $jailname /mnt/$($storage1)/downloads/torrents/completed /mnt/torrents nullfs rw 0 0
#Configure jail
iocage exec $jailname mkdir -p /config/transmission-home
iocage exec $jailname "pw user add $($sharedAccountName) -c $($sharedAccountName) -u $($sharedAccountUID) -d /nonexistent -s /usr/bin/nologin"
iocage exec $jailname chown -R $($sharedAccountName):$($sharedAccountName) /config
iocage exec $jailname sysrc "transmission_enable=YES"
iocage exec $jailname sysrc "transmission_conf_dir=/config/transmission-home"
iocage exec $jailname sysrc "transmission_download_dir=/mnt/torrents/completed"
iocage exec $jailname sysrc "transmission_user=$($sharedAccountName)"
iocage exec $jailname sysrc "transmission_group=$($sharedAccountName)"
iocage exec $jailname service transmission start
iocage exec $jailname service transmission stop
iocage exec $jailname ee /config/transmission-home/settings.json
#Manual steps
## Modify "rpc-whitelist-enabled" to equal false
"rpc-whitelist-enabled": false,

#Configure jail part 2
iocage exec $jailname service transmission start

## Transmission location
 http://$($jailIP4):9091/transmission/web/
"@
#endregion

#region SabNZBD
    #Localize variables
    $jailname = $jailSabName
    $jailIP4 = $jailSabIP4
    $jailVnet = $jailSabVnet
    $jailCIDR = $jailSabCIDR
    $jailGateway = $jailSabGateway
$sabconfig = @"
#Initialize jail
echo '{"pkgs":["sabnzbdplus","ca_root_nss"]}' > /tmp/pkg.json
iocage create -n "$($jailname)" -p /tmp/pkg.json -r "$($jailRelease)" ip4_addr="$($jailVnet)$($jailIP4)$($jailCIDR)" defaultrouter="$($jailGateway)" vnet="on" allow_raw_sockets="1" boot="on" 
rm /tmp/pkg.json
mkdir /mnt/$($storage1)/appdata/$($jailname)
#Mount storage
iocage fstab -a $jailname /mnt/$($storage1)/appdata/$($jailname) /config nullfs rw 0 0
iocage fstab -a $jailname /mnt/$($storage1)/downloads/sabnzbd/ /mnt/downloads nullfs rw 0 0
#Configure jail
iocage exec $jailname ln -s /usr/local/bin/python2.7 /usr/bin/python
iocage exec $jailname ln -s /usr/local/bin/python2.7 /usr/bin/python2
iocage exec $jailname "pw user add $($sharedAccountName) -c $($sharedAccountName) -u $($sharedAccountUID) -d /nonexistent -s /usr/bin/nologin"
iocage exec $jailname chown -R $($sharedAccountName):$($sharedAccountName) /mnt/downloads/sabnzbd /config
iocage exec $jailname sysrc sabnzbd_enable=YES
iocage exec $jailname sysrc sabnzbd_conf_dir="/config"
iocage exec $jailname sysrc sabnzbd_user="$($sharedAccountName)"
iocage exec $jailname sysrc sabnzbd_group="$($sharedAccountName)"
iocage exec $jailname service sabnzbd start
iocage exec $jailname service sabnzbd stop
iocage exec $jailname sed -i '' -e 's?download_dir = Downloads/incomplete?download_dir = /mnt/downloads/sabnzbd/incomplete?g' /config/sabnzbd.ini
iocage exec $jailname sed -i '' -e 's?complete_dir = Downloads/complete?complete_dir = /mnt/downloads/sabnzbd/complete?g' /config/sabnzbd.ini
iocage exec $jailname service sabnzbd start

## SABNZBD location
http://192.168.1.20:8080/sabnzbd/
"@

#endregion

#region nzbhydra2
    #Localize variables
    $jailname = $jailHydraName
    $jailIP4 = $jailHydraIP4
    $jailVnet = $jailHydraVnet
    $jailCIDR = $jailHydraCIDR
    $jailGateway = $jailHydraGateway
$hydraConfig = @"
#Initialize jail
echo '{"pkgs":["openjdk8","wget","python","curl"]}' > /tmp/pkg.json
iocage create -n "$($jailname)" -p /tmp/pkg.json -r "$($jailRelease)" ip4_addr="$($jailVnet)$($jailIP4)$($jailCIDR)" defaultrouter="$($jailGateway)" vnet="on" allow_raw_sockets="1" boot="on" 
rm /tmp/pkg.json
mkdir /mnt/$($storage1)/appdata/$($jailname)
#Mount storage
iocage fstab -a $jailname /mnt/$($storage1)/appdata/$($jailname) /config nullfs rw 0 0
#Configure jail
iocage exec $jailname "pw user add $($sharedAccountName) -c $($sharedAccountName) -u $($sharedAccountUID) -d /nonexistent -s /usr/bin/nologin"
iocage exec $jailname mkdir /usr/local/share/nzbhydra
iocage exec $jailname "fetch https://github.com/theotherp/nzbhydra2/releases/download/v2.4.3/nzbhydra2-2.4.3-linux.zip -o /usr/local/share"
iocage exec $jailname unzip -d /usr/local/share/nzbhydra /usr/local/share/nzbhydra2-2.4.3-linux.zip
iocage exec $jailname "fetch https://raw.githubusercontent.com/theotherp/nzbhydra2/master/other/wrapper/nzbhydra2wrapper.py -o /usr/local/share/nzbhydra"
iocage exec $jailname chown -R "$($sharedAccountName):$($sharedAccountName) /usr/local/share/nzbhydra/nzbhydra2*"
iocage exec $jailname chown -R $($sharedAccountName):$($sharedAccountName) /config
iocage exec $jailname "chmod +x /usr/local/share/nzbhydra2*"
iocage exec $jailname mkdir /usr/local/etc/rc.d
iocage exec $jailname ee /usr/local/etc/rc.d/nzbhydra

#Manual steps

#!/bin/sh
#
# PROVIDE: nzbhydra
# REQUIRE: LOGIN
# KEYWORD: shutdown
#
# Add the following lines to /etc/rc.conf.local or /etc/rc.conf
# to enable this service:
#
# nzbhydra_enable (bool):       Set to NO by default.
#                       Set it to YES to enable it.
# nzbhydra_user:        The user account nzbhydra daemon runs as what
#                       you want it to be. It uses '_sabnzbd' user by
#                       default. Do not sets it as empty or it will run
#                       as root.
# nzbhydra_group:       The group account nzbhydra daemon runs as what
#                       you want it to be. It uses '_sabnzbd' group by
#                       default. Do not sets it as empty or it will run
#                       as wheel.
# nzbhydra_data_dir:    Directory where nzbhydra configuration
#                       data is stored.
#                       Default: /var/db/nzbhydra

. /etc/rc.subr
name="nzbhydra"
rcvar="${name}_enable"
load_rc_config ${name}

: ${nzbhydra_enable:="NO"}
: ${nzbhydra_user:="$($sharedAccountName)"}
: ${nzbhydra_group:="$($sharedAccountName)"}
: ${nzbhydra_data_dir:="/config"}

pidfile="/var/run/nzbhydra/nzbhydra.pid"
command="/usr/local/bin/python2.7"
command_args="/usr/local/share/nzbhydra/nzbhydra2wrapper.py --datafolder ${nzbhydra_data_dir} --pidfile ${pidfile} --daemon --nobrowser"

start_precmd="nzbhydra_prestart"
nzbhydra_prestart() {
        if [ ! -d ${pidfile%/*} ]; then
                install -d -o ${nzbhydra_user} -g ${nzbhydra_group} ${pidfile%/*}
        fi

        if [ ! -d ${nzbhydra_data_dir} ]; then
                install -d -o ${nzbhydra_user} -g ${nzbhydra_group} ${nzbhydra_data_dir}
        fi
}

run_rc_command "$1"
#Configure jail part 21

iocage exec $jailname chmod u+x /usr/local/etc/rc.d/nzbhydra
iocage exec $jailname sysrc "nzbhydra_enable=YES"
iocage exec $jailname sysrc "nzbhydra_user=$($sharedAccountName)"
iocage exec $jailname sysrc "nzbhydra_group=$($sharedAccountName)"
iocage exec $jailname sysrc "nzbhydra_data_dir=/config"
iocage exec $jailname service nzbhydra start

## Hydra location
https://$($jailIP4):5076
"@
#endregion


#region Lidarr
    #Localize variables
    $jailname = $jailLidarrName
    $jailIP4 = $jailLidarrIP4
    $jailVnet = $jailLidarrVnet
    $jailCIDR = $jailLidarrCIDR
    $jailGateway = $jailLidarrGateway
$lidarrConfig = @"
#Initialize jail
echo '{"pkgs":["mono","mediainfo","sqlite3","ca_root_nss","curl"]}' > /tmp/pkg.json
iocage create -n "$($jailname)" -p /tmp/pkg.json -r "$($jailRelease)" ip4_addr="$($jailVnet)$($jailIP4)$($jailCIDR)" defaultrouter="$($jailGateway)" vnet="on" allow_raw_sockets="1" boot="on" 
rm /tmp/pkg.json
mkdir /mnt/$($storage1)/appdata/$($jailname)
mkdir /mnt/$($storage1)/downloads/torrents
mkdir /mnt/$($storage1)/downloads/torrents/completed    
mkdir /mnt/$($storage1)/downloads/sabnzbd
mkdir /mnt/$($storage1)/downloads/sabnzbd/music
#Mount storage
iocage fstab -a $jailname /mnt/$($storage1)/appdata/$($jailname) /config nullfs rw 0 0
iocage fstab -a $jailname /mnt/$($storage1)/downloads/torrents/completed /mnt/torrents nullfs rw 0 0
iocage fstab -a $jailname /mnt/$($storage1)/downloads/sabnzbd/music /mnt/nzbd nullfs rw 0 0
iocage fstab -a $jailname /mnt/$($storage1)/media/music /mnt/music nullfs rw 0 0
#Configure jail
iocage exec $jailname ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec $jailname "fetch https://github.com/lidarr/Lidarr/releases/download/v0.2.0.371/Lidarr.develop.0.2.0.371.linux.tar.gz -o /usr/local/share"
iocage exec $jailname "tar -xzvf /usr/local/share/Lidarr.develop.*.linux.tar.gz -C /usr/local/share"
iocage exec $jailname "rm /usr/local/share/Lidarr.*.tar.gz"
iocage exec $jailname "pw user add $($sharedAccountName) -c $($sharedAccountName) -u $($sharedAccountUID) -d /nonexistent -s /usr/bin/nologin"
iocage exec $jailname chown -R $($sharedAccountName):$($sharedAccountName) /usr/local/share/Lidarr /config
iocage exec $jailname mkdir /usr/local/etc/rc.d
iocage exec $jailnamearr ee /usr/local/etc/rc.d/lidarr
#Manaul steps

#!/bin/sh

# $FreeBSD$
#
# PROVIDE: lidarr
# REQUIRE: LOGIN
# KEYWORD: shutdown
#
# Add the following lines to /etc/rc.conf to enable lidarr:
# lidarr_enable="YES"

. /etc/rc.subr
name=lidarr
rcvar=${name}_enable
load_rc_config $name

: ${lidarr_enable="NO"}
: ${lidarr_user:="$($sharedAccountName)"}
: ${lidarr_group:="$($sharedAccountName)"}
: ${lidarr_data_dir:="/config"}

pidfile="${lidarr_data_dir}/lidarr.pid"
command="/usr/sbin/daemon"
procname="/usr/local/bin/mono"
command_args="-f ${procname} /usr/local/share/Lidarr/Lidarr.exe -- data=${lidarr_data_dir} --nobrowser"

start_precmd=lidarr_precmd
lidarr_precmd() {
if [ ! -d ${lidarr_data_dir} ]; then
install -d -o ${lidarr_user} -g ${lidarr_group} ${lidarr_data_dir}
fi

export XDG_CONFIG_HOME=${lidarr_data_dir}
}

run_rc_command "$1"

#Configure jail part 2
iocage exec $jailname chmod u+x /usr/local/etc/rc.d/lidarr
iocage exec $jailname sysrc "lidarr_enable=YES"
iocage exec $jailname sysrc "lidarr_user=$($sharedAccountName)"
iocage exec $jailname sysrc "lidarr_group=$($sharedAccountName)"
iocage exec $jailname service lidarr start

## Lidarr location
http://$($jailIP4):8686
"@
#endregion

#Create config files
mkdir .\JailConfig
$plexConfig | Out-file -FilePath .\JailConfig\$($jailPlexName).txt -Encoding utf8 -Force
$tautulliConfig | Out-file -FilePath .\JailConfig\$($jailTautulliName).txt -Encoding utf8 -Force
$radarrConfig | Out-file -FilePath .\JailConfig\$($jailRadarrName).txt -Encoding utf8 -Force
$sonarrConfig | Out-file -FilePath .\JailConfig\$($jailSonarrName).txt -Encoding utf8 -Force
$transmissionConfig | Out-file -FilePath .\JailConfig\$($jailTransmissionName).txt -Encoding utf8 -Force
$sabconfig | Out-file -FilePath .\JailConfig\$($jailSabName).txt -Encoding utf8 -Force
$hydraConfig | Out-file -FilePath .\JailConfig\$($jailHydraName).txt -Encoding utf8 -Force
$lidarrConfig | Out-file -FilePath .\JailConfig\$($jailLidarrName).txt -Encoding utf8 -Force

#endregion