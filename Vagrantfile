Vagrant.configure("2") do |config|
  #Common settings
  config.vm.provider :virtualbox do |vb|
    vb.customize [
      "modifyvm", :id,
      "--cpuexecutioncap", "50",
      "--memory", 1600,
    ]
  end

  config.hostmanager.enabled = true
  config.hostmanager.manage_guest = true


  config.ssh.username = 'vagrant'
  config.ssh.private_key_path = "~/.ssh/id_rsa"
  config.ssh.forward_agent = true
  config.ssh.password = 'vagrant'
  config.ssh.insert_key = true

  #Master
  config.vm.define "k8smaster001" do |master|
    master.vm.box = "k8s_base"
    master.vm.hostname = "k8smaster001.local"
    master.vm.network "public_network"
    master.vm.provider "virtualbox" do |v|
      v.name = "k8smaster001"
    end
    master.vm.provision "shell",
      run: "always",
      inline: "ifconfig enp0s8 192.168.0.171 netmask 255.255.255.0 up"
    master.vm.provision "shell",
      run: "always",
      inline: "route add -net 192.168.0.0 netmask 255.255.255.0 enp0s8"
    master.vm.provision "shell",
      run: "always",
      inline: "route add default gw 192.168.0.1 enp0s8"
    master.vm.provision "shell",
      run: "always",
      inline: "route del default enp0s3"
  end

  (1..2).each do |i|
    config.vm.define "k8sworker00#{i}" do |worker|
      worker.vm.box = "k8s_base"
      worker.vm.hostname = "k8sworker00#{i}.local"
      #worker.vm.provision :shell, :path => "scripts/bootstrap.sh"
      worker.vm.network "public_network", ip: "192.168.0.18#{i}", bridge: "enp0s8: Wired connection 1"
      worker.vm.provider "virtualbox" do |v|
        v.name = "k8sworker00#{i}"
      end
      worker.vm.provision "shell",
        run: "always",
        inline: "ifconfig enp0s8 192.168.0.18#{i} netmask 255.255.255.0 up"
      worker.vm.provision "shell",
        run: "always",
        inline: "route add -net 192.168.0.0 netmask 255.255.255.0 enp0s8"
      worker.vm.provision "shell",
        run: "always",
        inline: "route add default gw 192.168.0.1 enp0s8"
      worker.vm.provision "shell",
        run: "always",
        inline: "route del default enp0s3"
    end
  end
end
