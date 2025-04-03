This project is to create a linux device which accepts Airplay input & input from a line-in ( mic ) 

Basically I want my amp to be able to handle multiple inputs without the need for me to switch it. 

This repo also handles Amplifier control using a Tasmota. The amp is connected via a tasmota device.

If no input audio is detected over a time period of 10 mins, it automatically turns off the Amplifier using Tasmota HTTP calls.
