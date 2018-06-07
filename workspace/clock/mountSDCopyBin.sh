#!/bin/bash

echo "mount /dev/sdb1"

sudo mount /dev/sdc1 /mnt/mydisk


sudo cp ./led.bin /mnt/mydisk/images/noos.bin

cd ~

sudo umount /dev/sdc1
