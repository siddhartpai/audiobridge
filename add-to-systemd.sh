#!/bin/bash

cp ./systemd.confs/*.service ~/.config/systemd/user/
cp ./systemd.confs/*.timer ~/.confif/systemd/user/

systemctl --user daemon-reload


systemctl --user enable jackd.service
systemctl --user enable shairport.service
systemctl --user enable post_shairport.service
systemctl --user enable amp_control.service
systemctl --user enable --now jack-healthcheck.timer

