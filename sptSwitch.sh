#!bin/sh

help_text="sptSwitch is a utility to switch spotifyd audio output easily using pacmd.

Usage:
  sptSwitch sp - switch to speakers
  sptSwitch hp - switch to headphones
  sptSwitch help - display this message"

spt_full_inputs=$(pacmd list-sink-inputs);

inputs=$(grep -oP 'application.process.binary = "\K[^"]+' <<< $spt_full_inputs);
# stores all indecies for input sources
full_index=$(grep -oP 'index:\s*\K[^\s]+' <<< $spt_full_inputs);

indx=1
# set this to a unrealistic number so we can check if index was ever found
spt_index=999

# search spotifyd index from pacmd
for sic in $full_index; do 
    src=$(echo $inputs | cut --delimiter " " --fields "$indx");
    if [[ $src == "spotifyd" ]]; then
        spt_index=$sic    
    fi
    ((indx++))
done

# use an array to store a command and the source 
# this will be moved to a config file 
declare -A src_arr;

conf_path="conf.txt"

while IFS= read -r line; do
  if [[ ! "$line" =~ ^# ]]; then
    IFS=',' read -r var1 var2 <<< "$line"
    src_arr[$var1]=$var2
  fi 
done < "$conf_path"

src_arr["hp"]="UMC202HD"
src_arr["sp"]="HD-Audio"

if [[ $spt_index -eq 999 ]]; then
    echo "Spotifyd not running" 
else 
    full_sinks=$(pacmd list-sinks);

    sinks=$(grep -oP 'alsa.card_name = "\K[^"]\S+' <<< $full_sinks);
    full_sink_index=$(grep -oP 'index:\s*\K[^\s]+' <<< $full_sinks);

    if [[ $1 == "" ]]; then
      echo "No parameter given. Use sptSwitch help to display help."
    elif [[ $1 == "help" ]]; then
      echo "$help_text"
    else
      indx=1
    
      for cmd in ${!src_arr[@]}; do
        if [[ $1 == $cmd ]]; then 
          # we need to find the correct id for given sink
          for sink_id in $full_sink_index; do
            sink_src=$(echo $sinks | cut --delimiter " " --fields "$indx");

            if [[ $sink_src == ${src_arr[${cmd}]} ]]; then
              echo "Setting sink-input $spt_index to sink ${src_arr[${cmd}]} "
              pacmd move-sink-input $spt_index $sink_id
              fi
            ((indx++))
          done
        fi
      done
    fi
fi
