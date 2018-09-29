#!/bin/bash
cp -f /vagrant/hosts.k8s /etc/hosts
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
swapoff -a


# common Networking
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10255/tcp
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# Latest supported version of docker for k8s 1.11
yum install -y docker-ce-selinux-17.03.0.ce-1.el7 docker-ce-17.03.3.ce-1.el7 --setopt=obsoletes=0
cp /vagrant/k8s.repo /etc/yum.repos.d/
yum install -y kubelet kubeadm kubectl

sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl daemon-reload
systemctl enable docker.service
systemctl enable kubelet
systemctl start kubelet
systemctl start docker.service

if [ `hostname` == "k8smaster001.local" ]; then

	firewall-cmd --permanent --add-port=6443/tcp
	firewall-cmd --permanent --add-port=2379-2380/tcp
	firewall-cmd --permanent --add-port=10251/tcp
	firewall-cmd --permanent --add-port=10252/tcp
	firewall-cmd --reload
	# Init cluster
	# Calico
	# kubeadm init --apiserver-advertise-address=192.168.0.171 --pod-network-cidr=192.168.0.0/16 >/vagrant/cluster.info
	# Weave
	kubeadm init --apiserver-advertise-address=192.168.0.171 >/vagrant/cluster.info
	# Config kubectl
	mkdir -p $HOME/.kube
	sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	sudo chown $(id -u):$(id -g) $HOME/.kube/config
	# Install overlay network - weave
	kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
	#kubectl apply -f /vagrant/k8s/calico.yaml
	#kubectl apply -f /vagrant/k8s/kubernetes-dashboard.yaml

	# Setup Dashboard Admin user
	# Create service account
	kubectl create serviceaccount cluster-admin-dashboard-sa

	# Bind ClusterAdmin role to the service account
	kubectl create clusterrolebinding cluster-admin-dashboard-sa \
	  --clusterrole=cluster-admin \
          --serviceaccount=default:cluster-admin-dashboard-sa

	# Parse the token
	TOKEN=$(kubectl describe secret $(kubectl -n kube-system get secret | awk '/^cluster-admin-dashboard-sa-token-/{print $1}') | awk '$1=="token:"{print $2}')
	echo $TOKEN > /vagrant/k8s/dashboard.token
else
	firewall-cmd --permanent --add-port=30000-32767/tcp
	firewall-cmd --permanent --add-port=6783/tcp
	firewall-cmd --reload
fi
