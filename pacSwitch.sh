#!bin/sh

help_text="
pacSwitch is a utility to switch pacmd audio from one sink to another easily.

Usage:
  sptSwitch <cmd> <app - optional> - switch to source given in config.
    cmd - specified in the config file
    app - must be in the exact name that pacmd list-sink-inputs gives
          under application.process.binary. Defaults to spotifyd

  sptSwitch help - display this message"

spt_full_inputs=$(pacmd list-sink-inputs);

inputs=$(grep -oP 'application.process.binary = "\K[^"]+' <<< $spt_full_inputs);
# stores all indecies for input sources
full_index=$(grep -oP 'index:\s*\K[^\s]+' <<< $spt_full_inputs);

indx=1
# set this to a unrealistic number so we can check if index was ever found
app_index=999

if [[ $2 == "" ]]; then    
  # use spotifyd as default app
  for sic in $full_index; do 
      src=$(echo $inputs | cut --delimiter " " --fields "$indx");
      if [[ $src == "spotifyd" ]]; then
          app_index=$sic    
      fi
      ((indx++))
  done
else
  # search app index from pacmd
  for sic in $full_index; do 
      src=$(echo $inputs | cut --delimiter " " --fields "$indx");
      if [[ $src == $2 ]]; then
          app_index=$sic    
      fi
      ((indx++))
  done
fi

# use an array to store a command and the source 
# this will be moved to a config file 
declare -A src_arr;

conf_path="/home/samuk/Desktop/coding/pacSwitch/cmdConf.txt"

# Read through conf file
# Check conf file for more details
while IFS= read -r line; do
  if [[ ! "$line" =~ ^# ]]; then
    IFS=',' read -r var1 var2 <<< "$line"
    src_arr[$var1]=$var2
  fi 
done < "$conf_path"

if [[ $1 == "" ]]; then
    echo "No parameter given. Use sptSwitch help to display help."
elif [[ $1 == "help" ]]; then
  echo "$help_text"
elif [[ $app_index -eq 999 ]]; then
    echo "$2 not found or not running" 
else 
    full_sinks=$(pacmd list-sinks);

    sinks=$(grep -oP 'alsa.card_name = "\K[^"]\S+' <<< $full_sinks);
    full_sink_index=$(grep -oP 'index:\s*\K[^\s]+' <<< $full_sinks);
    indx=1
  
    for cmd in ${!src_arr[@]}; do
      if [[ $1 == $cmd ]]; then 
        # we need to find the correct id for given sink
        for sink_id in $full_sink_index; do
          sink_src=$(echo $sinks | cut --delimiter " " --fields "$indx");

          if [[ $sink_src == ${src_arr[${cmd}]} ]]; then
            echo "Setting sink-input $app_index to sink ${src_arr[${cmd}]} "
            pacmd move-sink-input $app_index $sink_id
            fi
          ((indx++))
        done
      fi
    done
fi
