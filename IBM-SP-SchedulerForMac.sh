#!/bin/bash

# Check if MacPorts is already installed
if ! [ -x "$(command -v port)" ]; then
  # Install MacPorts if it is not already installed
  echo "MacPorts is not installed. Installing it now..."
  #/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/macports/macports-base/master/src/bootstrap/darwin.sh)"
  curl -O https://distfiles.macports.org/MacPorts/MacPorts-2.8.0.tar.bz2
  tar xf MacPorts-2.8.0.tar.bz2
  /bin/bash/ MacPorts-2.8.0/configure
  make
  sudo make install 
  export PATH=$PATH:/opt/local/bin
  port selfupdate

else
  echo "MacPorts is already installed."
fi

# Check if anacron is already installed
if ! [ -x "$(command -v anacron)" ]; then
  # Install anacron through MacPorts if it is not already installed
  echo "anacron is not installed. Installing it now..."
  sudo port install anacron
else
  echo "anacron is already installed."
fi

# Create the dsmc-incremental script

sudo mkdir -p /etc/cron.daily
sudo touch /etc/cron.daily/dsmc-incremental.sh

sudo cat > /etc/cron.daily/dsmc-incremental.sh <<EOF
#!/bin/bash
dsmc incremental
EOF

sudo chmod +x /etc/cron.daily/dsmc-incremental.sh

# Add a line to the anacrontab file to schedule the script to run every day
echo "1       5       dsmc-incremental       /etc/cron.daily/dsmc-incremental.sh" > /etc/anacrontab

echo "Operation completed successfully"
