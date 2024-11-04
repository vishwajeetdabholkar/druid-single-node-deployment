#!/bin/bash
# Update and install necessary packages
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk python3 perl mysql-server mysql-client
sudo apt install unzip 

# Setup MySQL
sudo systemctl start mysql
sudo systemctl enable mysql
sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root@123'; FLUSH PRIVILEGES;"

# Install ZooKeeper
cd /opt
sudo wget https://downloads.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz
sudo tar -xzf apache-zookeeper-3.8.4-bin.tar.gz
sudo mv apache-zookeeper-3.8.4-bin zookeeper
sudo touch /opt/zookeeper/conf/zoo.cfg
sudo bash -c 'cat > /opt/zookeeper/conf/zoo.cfg <<EOF
tickTime=2000
dataDir=/var/zookeeper
clientPort=2181
initLimit=5
syncLimit=2
EOF'
cd /opt/zookeeper/bin
sudo ./zkServer.sh start &

# Install Imply Manager
cd /opt
sudo curl -O "https://static.imply.io/release/imply-manager-2024.09.tar.gz"
sudo mv 'imply-manager-2024.09.tar.gz' imply-manager.tar.gz
sudo tar -xvf imply-manager.tar.gz
sudo mv 'imply-manager-2024.09' imply-manager
sudo ./imply-manager/script/install

# Update manager.conf
sudo bash -c 'cat > /etc/opt/imply/manager.conf <<EOF
IMPLY_MANAGER_STORE_TYPE=mysql
IMPLY_MANAGER_STORE_HOST=localhost
IMPLY_MANAGER_STORE_PORT=3306
IMPLY_MANAGER_STORE_USER=root
IMPLY_MANAGER_STORE_PASSWORD=root@123
IMPLY_MANAGER_STORE_DATABASE=imply_manager
IMPLY_MANAGER_STORE_SSLMODE=PREFERRED
imply_defaults_zkType=external
imply_defaults_zkHosts=localhost:2181
imply_defaults_zkBasePath=druid
imply_defaults_metadataStorageType=mysql
imply_defaults_metadataStorageHost=localhost
imply_defaults_metadataStoragePort=3306
imply_defaults_metadataStorageUser=root
imply_defaults_metadataStoragePassword=root@123
imply_defaults_deepStorageType=local
imply_defaults_deepStorageBaseLocation=/tmp/segments/
EOF'

# Start Imply Manager
sudo systemctl start imply-manager

# Install Imply Agent
sudo curl -O "https://static.imply.io/release/imply-agent-v7.tar.gz"
sudo mv 'imply-agent-v7.tar.gz' imply-agent.tar.gz
sudo tar -xvf imply-agent.tar.gz
sudo mv 'imply-agent-v7' imply-agent
sudo ./imply-agent/script/install

# Update agent.conf
sudo bash -c 'cat > /etc/opt/imply/agent.conf <<EOF
IMPLY_MANAGER_HOST=<private_ip_of_master_node>
IMPLY_MANAGER_AGENT_CLUSTER=<cluster_id_from_imply_manager>
IMPLY_MANAGER_AGENT_NODE_TYPE=master","query","data
EOF'

# Start Imply Agent
sudo systemctl start imply-agent