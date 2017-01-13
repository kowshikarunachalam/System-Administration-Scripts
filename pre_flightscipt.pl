#!/usr/bin/perl
#use strict;
use warnings;
use Term::ANSIColor;
#use Module::Load;
#load YAML;
#use YAML::Tiny;
#use JSON;
#use Data::Dumper;
#use YAML::Syck;
use File::stat;
use Fcntl ':mode';
my %hash;
my @okmessages;
my @criticalmessages;
my @notificationmessages;

## CHECK 1:Check if CDNNET STATE is in Service
#
#
#Script checks if 

print color("magenta"),"\nCHECK 1:Checking if CDNNET STATE is in Service \n",color("reset");
my $cdnstate = '/etc/cdnet.state';
if ( -e $cdnstate ){  ## Check for the existence of /ec/cdnet.state file 
open(DATA,"<$cdnstate") or print color("red"),"CRITICAL:Couldnt open file cdnnet.state file. Check if /etc/cdnet.state file is present \n",color("reset");

print color("magenta"),"cat /etc/cdnet.state \n",color("reset");

my $cdnstateprint = `cat /etc/cdnet.state`;
print color("magenta"),"$cdnstateprint",color("reset");

while (<DATA>){
if($_ =~ /(\S*)=(\S*)/){
(my $word1,my $word2 ) = split /=/,$_;
$hash{$word1} = $word2;
}
}
chomp $hash{CDNETSTATE};
if ( $hash{CDNETSTATE} eq "SERVICE") { # Checks if the value of CDNETSTATE = SERVICE 
 print color("green"),"OK:CDNETSTATE is in SERVICE \n",color("reset");
 push @okmessages, "OK:CDNETSTATE is in SERVICE \n";}
else {
 print color("red"), "CRITICAL:CDNETSTATE is not in SERVICE \n",color("reset"); ##CRITICAL : If the value of CDNETSTATE =! SERVICE
 push @criticalmessages, "CRITICAL:CDNETSTATE is not in SERVICE \n";
} }
else ## CRITICAL: If /etc/cdnet.state file is not present
{
print color("red"),"CRITICAL:Couldnt find cdnnet.state file. Check if /etc/cdnet.state file is present \n",color("reset");
 push @criticalmessages, "CRITICAL:Couldnt find cdnnet.state file. Check if /etc/cdnet.state file is present \n";
}

## CHECK 2 : To check if the hostname is in proper Form 
## HOSTNAME should  be in form something.cdngp.net
print color("magenta"), "\nCHECK 2 : Checking if the hostname is in proper Form \n",color("reset");

my $hostname = `hostname`;
chomp $hostname;
if ( $hostname =~ /(\S*).cdngp.net/){ # Check if the hostname is in form something.cdngp.net
print color("green"),"OK:Hostname is set correctly $hostname \n",color("reset");
push @okmessages, "OK:Hostname is set correctly $hostname \n";}
else {
print color("red"),"CRITICAL:Hostname is not set correctly $hostname \n",color("reset");
push @criticalmessages, "CRITICAL:Hostname is not set correctly $hostname \n";
}

## CHECK 3 : To Check if puppet run is successful
print color("magenta"),"\nCHECK 3 : Checking if last puppet run is successful \n",color("reset");

## Puppet Check 1 :check if puppet directory is present 
my $puppet_dir = "/var/lib/puppet/state";
chomp $puppet_dir;
if( -d $puppet_dir){
print color("green"),"OK:Puppet Directory $puppet_dir is present \n",color("reset");
push @okmessages, "OK:Puppet Directory is present\n";}
else {
print color("red"),"CRITICAL:Puppet Directory $puppet_dir is not present.Puppet havent run. Run puppet manually and check if any erros\n",color("reset");
push @criticalmessages, "CRITICAL:Puppet Directory $puppet_dir is not present.Puppet havent run. Run puppet manually and check if any erros\n";} # CRITICAL : If the Puppet Directory is not present. This means Puppet havent run.  



##Puppet Check 2 : Check last_run_summary file
my $lastrunsummary="/var/lib/puppet/state/last_run_summary.yaml"; ## File last_run_summary.yaml contains all the information about last puppet check. 
if ( -f $lastrunsummary){
my $eventreturncode = `cat /var/lib/puppet/state/last_run_summary.yaml`;
if ($eventreturncode !~ /events/) { # If the file last_run_summary.yaml is incomplete, then last puppet run is not successful.
print color("red"),"CRITICAL:Last Puppet run is not successful\n",color("reset");
push @criticalmessages, "CRITICAL:Last Puppet run is not successful.Run puppet manually and check if any erros\n";
}

#if ( -f $lastrunsummary){
open(FAILURETEXT,"<$lastrunsummary"); 

while (<FAILURETEXT>){
if ($_ =~ /failure/) { ## Checks if there are any failures from the last file. If yes report the number of failures under Critical. 
(my $key,my $value) = split /:/,$_;
chomp $value;
if ($value >0){ ## If there are Failures report under CRITICAL.  
print color("red"),"CRITICAL:Puppet run has failures\n",color("reset");
push @criticalmessages, "CRITICAL:Puppet run has failures.Run puppet manually and check if any erros\n";}
else { ##OK if there are no error.
print color("green"),"OK:Last Puppet run is successful \n",color("reset");
push @okmessages, "OK:Last Puppet run is successful \n";
}

}

}}
else { ## Report Critical if the File $lastrunsummary is not present. 
print color ("red"),"Puppet havent run.Puppet File $lastrunsummary is not present. ",color("reset");
push @criticalmessages, "CRITICAL:Puppet run has failures.Run puppet manually and check if any erros\n";
}

###Check if Cache Partitions are mounted properly 
print color("magenta"),"\nCheck 4 : Checking if Cache Partitions are mounted properly \n",color("reset");
##Find total number of disks
#my $TotalNoofDisks = `egrep { cciss/c.d.|sd[a-z]|hd[a-z] } /proc/partitions`;
#my $TotalNoofDisks = `cat /proc/partitions | egrep  "{ cciss/c.d.|sd[a-z]|hd[a-z] }" | wc -l`;
#print $TotalNoofDisks;
##Find the number of cache volumes. (No of disks - 1) cache volumes should be present on the server
my $TotalNoofCache = `cat /proc/mounts  | grep -i cache[0-9]  | wc -l`; #Find Total Number of Cache Volumes Mounted
chomp $TotalNoofCache;
#my $cachetotalcheck = $TotalNoofDisks-$TotalNoofCache ;
if ($TotalNoofCache == 0 ) {  ## Check if there are No Cache Volumes
   print color("red"),"CRITICAL:There are no Cache Volumes \n",color("reset");
   push @criticalmessages, "CRIICAL:There are no Cache Volumes\n";}
#elsif ($cachetotalcheck >1 ){
#   print color("red"),"There are $TotalNoofDisks Number of Disks and there are $TotalNoofCache cache volumes . Check if correct number of Cache Volumes are created\n",color("reset");}    
else {
   print color("green"),"OK:There are  $TotalNoofCache cache volumes\n",color("reset");} 
## Check if any of  the Cache Volumes are Read-Only  
  unless ( $TotalNoofCache == 0 ){
  print color("magenta"),"Cache Volumes present are \n",color("reset");
    my %chachehash;
     for ( my $i=1; $i<=$TotalNoofCache;$i++ ) {
    #   my %chachehash;
my $filename = "/cache$i";
 print color("magenta"),"$filename \n",color("reset");
my $sb = stat ($filename);
my $mode = $sb->mode;
my $permission = sprintf "%04o",S_IMODE($mode);
my $uid = $sb->uid;
my $gid = $sb->gid;
my $user = getpwuid($uid);
my $group = getgrgid($gid);
$chachehash{"cache$i"}{"permission"} = $permission;
$chachehash{"cache$i"}{"user"} = $user;
$chachehash{"cache$i"}{"group"}= $group;
}
print color("magenta"),"\nCheck 5: Checking if Cache mounts have proper File permissions and Owner\n",color("reset");
#print keys %chachehash;
foreach my $key ( sort (keys(%chachehash))) {
# print color("magenta"),"$key has $chachehash{"cache$i"}{"permission"} and owned by $chachehash{"cache$i"}{"user"} and group $chachehash{"cache$i"}{"group"}\n",color("reset");
print color("magenta"),"$key has Permission:$chachehash{$key}{permission} Owner:$chachehash{$key}{user} Group: $chachehash{$key}{group} \n",color("reset");
}
#}
#}

#print $chachehash{cache1}{permission};
#Cache Volumes should have 755 Permission. Owner should be "http". Group should be "http".
my $OKCount = 0;
my $warningcount = 0 ;
for ( my $i=1; $i<=$TotalNoofCache;$i++ ) {
# print $chachehash{"cache$i"}{"permission"};
    if ( $chachehash{"cache$i"}{"permission"} ne "0755" ) {
        print color("yellow"),"CRITICAL:Permission Check Volume cache$i is having  instead of 755 \n",color("reset");
        #push @criticalmessages, "CRITICAL:Permission Check Volume cache$i is having  instead of 755 \n";
         $OKCount = 1;
         $warningcount = 1 ;
      } 
       # else {
       # print color("green"),"OK: Permission Check: Volume cache$i is having correct file permission 755 \n",color("reset");
       # push @okmessages, "OK: Permission Check: Volume cache$i is having correct file permission 755 \n";
       #else {
         #  int color("green"),"Permission Check : Volume cache$i is having different permission " \n",color("reset");}
          if ( $chachehash{"cache$i"}{"user"} !~ /http/){
             print color("yellow"),"CRITICAL:User Permission Check : Volume cache$i is owned by different user instead of http \n",color("reset");
         #    push @criticalmessages, "CRITICAL: User Permission Check : Volume cache$i is owned by different user instead of http \n";
             $OKCount = 1;
             $warningcount = 1 ;   
}
              #  else {
               #    print color("green"),"OK:Permission Check: Volume cache$i is having correct user permission \n",color("reset");
                #   push @okmessages, "OK:Permission Check: Volume cache$i is having correct user permission \n";
#}
                  
                      if ( $chachehash{"cache$i"}{"group"} !~ /cdn/){
                         print color("yellow"),"CRITICAL:Permission Check: Volume cache$i is having different group instead of cdn \n",color("reset");
          #             push @criticalmessages, "CRITICAL:Permission Check: Volume cache$i is having different group instead of cdn \n";
                       $OKCount = 1;
                        $warningcount = 1 ;
                        }
                   #      else {
                    #        print color("green"),"OK:Permission Check: Volume cache$i is having correct group permission  \n",color("reset");
                     #       push @okmessages, "OK:Permission Check: Volume cache$i is having correct group permission  \n";}
# }

                            }
                 if ( $OKCount  == 0 ) {
                    print  color("green"),"All Cache Volumes have right Permissions. \n",color("reset");
                    push @okmessages, "OK:All Cache Volumes have right Permissions. \n" ;
}
                  if ( $warningcount == 1) {
                      push @warningmessages, "WARNING: Cache Mounts have different Permissions. \n",color("reset");
}
}


#Check 4:Check if the Hostname is registered in IHMS. To check the script will check if the hostname is resolvable"

print  color("magenta"),"\nCheck 6:Checking if the Hostname is registered in IHMS\n",color("reset");

#my $hostname = `hostname`;
#my $hostname1 = gethostbyname($hostname) or die "Can't resolve $hostname: $!\n";
#my $command = "nslookup $hostname";
#my $test = gethostbyname($hostname);
#my $command = gethostbyname($hostname);
#my $returncode =  $?;
#chomp $returncode;
#chomp $hostname;
#print "Return Code is $returncode";
#if ( $returncode == 1 )
#{
#print color("green"),"OK:Hostname  $hostname is registered in IHMS  \n",color("reset");
#push @okmessages, "OK:Hostname  $hostname is registered in IHMS  \n";
#}
#else {
#print color("red"),"CRITICAL:Hostname $hostname is not registered in IHMS  \n",color("reset");
#push @criticalmessages, "CRITICAL:Hostname $hostname is not registered in IHMS  \n";
#}

if ( defined(my  $lookup = gethostbyname($hostname)))
    {
    print color("green"),"OK:Hostname  $hostname is registered in IHMS  \n",color("reset");
    push @okmessages, "OK:Hostname  $hostname is registered in IHMS  \n";
    }
    else
    {
    print color("red"),"CRITICAL:Hostname $hostname is not registered in IHMS  \n",color("reset");
    push @criticalmessages, "CRITICAL:Hostname $hostname is not registered in IHMS  \n";
    }

## Print Summary of OK & CRITICAL Messages
#print color("yellow"), "\t SUMMARY \n ",color("reset") ;
#print "----------------------------------------------------------------------------------------------- \n";
#print color("green"),"@okmessages",color("reset");
#print color("red"),"@criticalmessages",color("reset");

##Check 5 : To check if Bonding is enabled
my @interface;
my @macaddress;
my $bondokcount = 0;
my $bondingstate = '/proc/net/bonding/bond0';
if ( -e $bondingstate ){ 
print color("magenta"),"Bond Check:Bonding is enabled \n",color("reset");

##To find how many interfaces are bonded 


my $TotalNoofBond = `cat /proc/net/bonding/bond0 | grep -i "Slave Interface" | wc -l`;
chomp $TotalNoofBond;
if ($TotalNoofBond == 0 ) { ##Alert if the bonded interfaces is zero
print color("red"),"Bond Check:There are no bonded interfaces. Check if interfaces are bonded \n",color("reset");
push @criticalmessages, "CRITICAL:Bond Check: There are no bonded interfaces. Check if interfaces are bonded \n",color("reset");
$bondokcount = 1;
}
else {
print color("magenta"),"Bond Check: There are $TotalNoofBond Bonding interfaces \n",color("reset");
my $Bondinterfacename = `cat /proc/net/bonding/bond0 | grep -i "Slave Interface"`;
chomp $Bondinterfacename;
my @lines = split /\n/,$Bondinterfacename;
foreach my $line (@lines){
(my $key,my $value) = split /:/,$line;
chomp $value;
push @interface, $value;
}
print color("magenta"),"Bond Check: Interfaces Configured are @interface\n",color("reset");

##Check the Interface state
foreach my $interfaces (@interface){
my $interfaceOuput = `mii-tool $interfaces`;
$interfaceOuput =~ /^(.*)(link)\s+(\w+)/;
my $interfacestate = $3;
chomp $interfacestate;
if ( $interfacestate =~ /ok/){
print color("magenta"),"Bond Check: Interface $interfaces state is UP\n",color("reset");
}
else{
print color("red"),"Bond Check:Interface $interfaces state is DOWN. Check state of $interfaces by ip link show command\n",color("reset");
push @criticalmessages, "Bond Check: Interface $interfaces state is DOWN. Check state of $interfaces by ip link show command\n";
$bondokcount = 1;
}
}
#Check if Mac Address of all the Bonded interface are same
my %interfacehash;
foreach my $interfaces (@interface){
my $interfaceOuput1 = `ip link show $interfaces`;
#$interfaceOuput1 =~ /^(.*)(\S*:\S*:\S*:\S*:\S*:\S*)/;
$interfaceOuput1 =~ /((?:[0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2})/;
#my $macaddress = $1;
#print "#######$1################";
push @macaddress,$1;
$interfacehash{"$interfaces"} = $1;
#print @macaddress;
#$macaddress{$interfaces} = $1;
}
my $bondinterface = `ip link show bond0`;
$bondinterface =~ /((?:[0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2})/;
$interfacehash{"bond0"} = $1;
foreach my $key  ((sort keys(%interfacehash))) {
#$key =~ s/^\s+//;
#print $key;
print color("magenta"),"$key has Macaddress $interfacehash{$key}\n",color("reset");
}
my $n = $TotalNoofBond -1;
for (my $i=0;$i<=$n;$i++){
chomp $n;
  if ( $macaddress[$n] eq $macaddress[$i]){
   print color("magenta"),"Bond Check: Mac Addrres matches\n",color("reset");
}
else {
  print  color("red"),"Bond Check: Mac Address is not matching",color("reset");
  push @criticalmessages, "Bond Check: Mac Address is not matching",color("reset");
  $bondokcount = 1;
 }
}
}

}
else {
print color("magenta"),"Bond Check: Bonding is not enabled \n",color("reset");
push @notificationmessages, "Bond check: Bonding is not enabled \n",color("reset");
$bondokcount = 1;
}
if ($bondokcount ==0){
print color("green"),"OK:Bond Check: Bonding is configured and all interfaces state are UP\n",color("reset");
push @okmessages,"OK:Bond Check: Bonding is configured and all interfaces state are UP\n",color("reset");
}

## Print Summary of OK & CRITICAL Messages
print "----------------------------------------------------------------------------------------------- \n";
print color("yellow"), "\t SUMMARY \n ",color("reset") ;
print "----------------------------------------------------------------------------------------------- \n";
print color("green"),@okmessages,color("reset");
print color("blue"),@notificationmessages,color("reset");
print color("yellow"),@warningmessages,color("reset");
print color("red"),@criticalmessages,color("reset");
print "----------------------------------------------------------------------------------------------- \n";

