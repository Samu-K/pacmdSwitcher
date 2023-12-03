An cli app for linux to switch output sink from an audio source easily using pacmd.

Requirements:

    Pulseaudio - for pacmd
  
    Currently usage by commands requires setting up an alias in .bashrc (or similar)

Usage:

    pacSwitch <cmd> <app>
  
      - cmd is defined in config by user. This is what selects what sink to send audio
    
      - app describes what app's audio should be switched.

    pacSwitch help - Display a help message
