#!/bin/bash
# modify 2015.09.10 
# up ,down Bandwidth unit is Kbits/sec
# $1 for ip address
# $2 .sh run time
# $3 iperf3 -t time
# add ping_lost 
# retry fun
# kill iperf sleep 5
# fix nan error 
# add Supervision iperf3 
# add judgement root
# fix File_Modify == 
# add Internet_IP 
# remove sleep,300s
# export LD_LIBRARY_PATH
# cat ./files/${time1}_iperf.csv
export LD_LIBRARY_PATH=/usr/local/lib/
#### judgement root ######################################################################
root_id=`id -u`
if [ $root_id -ne 0 ] ; then
{
   clear
   echo -e "\033[40;37mWarning: you are not root user ! \n\n[Please use Command line ]$ sudo su \n\n \033[0m"
   exit 10
}
fi
####### Get localhost IP & Initialization for iperf.csv############################3
clear
time4=`date +%s`
echo "$time4"
time5=$[time4+$2] 
mkdir -p files
time1=`date "+%F-%H-%M"`
iperf="iperf3 -c $1 -t $3 -f k -p 12345 "
ifconfig en0 > files/tmp1
localIP=`sed -n "2p" files/tmp1|awk ‘{print $2}‘|cut -d: -f2`
echo -e "\033[43;38;1mget for Internet IP .........\033[0m"
wget http://members.3322.org/dyndns/getip >> /dev/null 2>&1
Internet_IP=`cat getip`
echo -e "\033[42;38;1mInternet IP :$Internet_IP\033[0m"
sleep 3
rm -rf getip
echo "Localhost,Ethernet_IP,$localIP" >>  ./files/${time1}_iperf.csv
echo "Localhost,Internet_IP,$Internet_IP" >>  ./files/${time1}_iperf.csv
echo "Remote,$1" >> ./files/${time1}_iperf.csv
echo "Bandwidth Kbits/sec" >>  ./files/${time1}_iperf.csv
echo "" >>  ./files/${time1}_iperf.csv
echo "Date,Start_Time,End_time,Up_Sender,Up_Receiver,Down_Sender,Down_Receiver,Jitter/ms,Lost/Total,Ping_Latency/ms,Ping_Lost" >> ./files/${time1}_iperf.csv
#exit
##### Supervision iperf3 #############################################
while [ $time4 -le $time5 ]
do
     sleep1=600
     File_Modify1=`stat ./files/tmp1 | tail -n 2| head -n 1| awk ‘{print $3}‘`
     sleep $sleep1 
     File_Modify2=`stat ./files/tmp1 | tail -n 2| head -n 1| awk ‘{print $3}‘`
     if [ $File_Modify1 == $File_Modify2 ]
     then
          killall iperf3 >> /dev/null 2>&1
          sleep 1
          killall iperf3 >> /dev/null 2>&1
          echo -e "`date`"
          echo -e "\n\n\n\033[41;37m kill zombie iperf3 ..............\033[0m"
          sleep 1
     else
          echo -e "\033[42;37m iperf3 Runing,Has not become zombie ,Every $sleep1 Seconds Check Once  .........\033[0m"
          echo -e "\033[42;38;1mInternet IP :$Internet_IP\033[0m"
     fi
time4=`date +%s`
done &
# Begin ##############################################
while [ $time4 -le $time5 ]
do
    time2=`date "+%F"`            # Get current time
    time3=`date "+%H:%M:%S"`
   echo "##########################################################################"
   echo -e "`date`"
   echo "Get ping information .....ping -c 30 $1"
    ping -c 30 $1 | tee ./files/tmp1 
    tail -2 files/tmp1 > ./files/tmp2
    ping_Latency=`sed -n "2p" ./files/tmp2 | cut -d/ -f5`
    ping_lost=`sed -n "1p" ./files/tmp2 | awk ‘{print $6}‘`
    echo -e "`date`"
    echo -e "\033[43;31mping_delay:$ping_Latency ms \033[0m"
    echo -e "\033[43;31mping_lost:$ping_lost \033[0m"
  echo "##########################################################################"
  echo -e "\n\n`date`"
  echo "Get upload information........ $iperf "
    $iperf | tee ./files/tmp1
    grep "sender" files/tmp1
    stat=`echo $?`
    grep "iperf Done" files/tmp1
    stat_done=`echo $?`
       while ( [ $stat != 0 ] || [ $stat_done != 0 ] ) 
       do
         killall iperf3 >> /dev/null 2>&1
         sleep 2
         killall iperf3 >> /dev/null 2>&1
         echo -e "`date`"
         echo "Retry Get upload information........ $iperf  "
         sleep 5
         $iperf  | tee ./files/tmp1
         grep "sender" files/tmp1
         stat=`echo $?`
         grep "iperf Done" files/tmp1
         stat_done=`echo $?`
       done
    tail -4 ./files/tmp1 > ./files/tmp2
      up_sender=`sed -n "1p" ./files/tmp2 | awk ‘{print $7}‘`
    up_receiver=`sed -n "2p" ./files/tmp2 | awk ‘{print $7}‘`
    echo -e "\033[43;31mup_sender: $up_sender Kbits/sec\033[0m"
    echo -e "\033[43;31mup_receiver:$up_receiver Kbits/sec\033[0m"
  echo "##########################################################################"
  echo "Get download information........ $iperf -R  "
    $iperf -R | tee ./files/tmp1
    grep "sender" files/tmp1
    stat=`echo $?`
    grep "iperf Done" files/tmp1
    stat_done=`echo $?`
       while ( [ $stat != 0 ] || [ $stat_done != 0 ] ) 
       do
         killall iperf3 >> /dev/null 2>&1
         sleep 2
         killall iperf3 >> /dev/null 2>&1
         echo -e "`date`"
         echo "Retry Get download information........ $iperf -R  "
         sleep 5
         $iperf -R | tee ./files/tmp1
         grep "sender" files/tmp1
         stat=`echo $?`
         grep "iperf Done" files/tmp1
         stat_done=`echo $?`
       done
    tail -4 ./files/tmp1 > ./files/tmp2
      down_sender=`sed -n "1p" ./files/tmp2 | awk ‘{print $7}‘`
    down_receiver=`sed -n "2p" ./files/tmp2 | awk ‘{print $7}‘`
    echo -e "\033[43;31mdown_sender:$down_sender Kbits/sec\033[0m"
    echo -e "\033[43;31mdown_receiver:$down_receiver Kbits/sec\033[0m"
  echo "##########################################################################"
  echo -e "Get UDP information start at...... $iperf -u -b 50M "
    $iperf -u -b 50M 
    $iperf -u -b 10M
    $iperf -u -b 20M
    $iperf -u -b 40M
    $iperf -u -b 30M
    $iperf -u -b 25M  | tee ./files/tmp1
    grep "Sent" ./files/tmp1
    stat=`echo $?`
    echo $stat
    grep "nan" files/tmp1
    stat2=`echo $?`
    grep "iperf Done" files/tmp1
    stat3=`echo $?`
    tail -4 ./files/tmp1 > ./files/tmp2
    Jitter=`sed -n "1p" ./files/tmp2 | awk ‘{print $9}‘`
    sed -n "1p" ./files/tmp2  |awk ‘{print $12}‘>./files/tmp1
    sed -i "s#(##g" ./files/tmp1
    sed -i "s#)##g" ./files/tmp1 
    Lost=`cat ./files/tmp1`
    echo -e "\033[43;31mJitter : $Jitter\033[0m"
    echo -e "\033[43;31mLost: $Lost \033[0m"
    echo "#########################################################################"
    time_end=`date "+%H:%M:%S"`
    echo $time_end
    echo -e "\033[45;37mlocal  IP is $localIP \033[0m"
    echo -e "\033[45;37mremote Ip is $1 \033[0m"
    echo "$time2,$time3,$time_end,$up_sender,$up_receiver,$down_sender,$down_receiver,$Jitter,$Lost,$ping_Latency,$ping_lost " >> ./files/${time1}_iperf.csv
    echo -e "\033[45;37mrecoder file save as  ./files/${time1}_iperf.csv \033[0m"
    cat ./files/${time1}_iperf.csv
    echo -e "\n\nsleep  300 seconds #####################################################\n\n\n\n"   
    echo -e "recoder file save as  ./files/${time1}_iperf.csv                 "
    rm -rf ./files/tmp1
    rm -rf ./files/tmp2
    sleep 300
time4=`date +%s`
done 
clear 
cat ./files/${time1}_iperf.csv
echo -e "\033[31m*******************************************************************\033[0m"
echo -e "Information Collection Complete !                        "
date
echo -e "recoder file save as  ./files/${time1}_iperf.csv                 "
echo -e "\033[31m*******************************************************************\033[0m" 
