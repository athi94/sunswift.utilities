#!/bin/bash
sudo 7zr x -o/usr/local/bin tools.7z
sudo mkdir /usr/local/bin/tools/extra/
sudo cp checksum /usr/local/bin/tools/extra/checksum
sudo chmod a+wrx -R /usr/local/bin/tools
#PATH=$PATH:/usr/local/bin/tools/bin:/usr/local/bin/tools/extra
echo "Please add the following line to your .bashrc file without the quotes:"
echo "PATH=$""PATH:/usr/local/bin/tools/bin:/usr/local/bin/tools/extra"
echo "If you are running 64 bit linux, please install the 32 bit compatibility libraries package: ia32-libs"