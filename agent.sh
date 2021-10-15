#!/bin/bash


echo "

██████╗░░█████╗░██╗  ████████╗░█████╗░  ░█████╗░██╗░░██╗░█████╗░████████╗░█████╗░
██╔══██╗██╔══██╗██║  ╚══██╔══╝██╔══██╗  ██╔══██╗██║░░██║██╔══██╗╚══██╔══╝██╔══██╗
██████╔╝███████║██║  ░░░██║░░░███████║  ██║░░╚═╝███████║███████║░░░██║░░░██║░░██║
██╔═══╝░██╔══██║██║  ░░░██║░░░██╔══██║  ██║░░██╗██╔══██║██╔══██║░░░██║░░░██║░░██║
██║░░░░░██║░░██║██║  ░░░██║░░░██║░░██║  ╚█████╔╝██║░░██║██║░░██║░░░██║░░░╚█████╔╝
╚═╝░░░░░╚═╝░░╚═╝╚═╝  ░░░╚═╝░░░╚═╝░░╚═╝  ░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░░╚════╝░
"
sleep 3
#############################################################################
##################          Verificando uns negocio
#############################################################################
if readlink /proc/$$/exe | grep -q "dash"; then
	echo 'Rode esse script com o "bash", e não com "sh".'
	exit
fi

if [[ "$EUID" -ne 0 ]]; then
	echo "Roda como root, animal"
	exit
fi

if grep -qs "ubuntu" /etc/os-release; then
	os="ubuntu"
	os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
	group_name="nogroup"
elif [[ -e /etc/debian_version ]]; then
	os="debian"
	os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
	group_name="nogroup"
elif [[ -e /etc/almalinux-release || -e /etc/rocky-release || -e /etc/centos-release ]]; then
	os="centos"
	os_version=$(grep -shoE '[0-9]+' /etc/almalinux-release /etc/rocky-release /etc/centos-release | head -1)
	group_name="nobody"
elif [[ -e /etc/fedora-release ]]; then
	os="fedora"
	os_version=$(grep -oE '[0-9]+' /etc/fedora-release | head -1)
	group_name="nobody"
else
	echo "This installer seems to be running on an unsupported distribution.
Supported distros are Ubuntu, Debian, AlmaLinux, Rocky Linux, CentOS and Fedora."
	exit
fi

if [[ "$os" == "ubuntu" && "$os_version" -lt 2004 ]]; then
	echo "Versão do anterior a 20.04 detectada, avisa o Guedao"
	exit
fi

if [[ "$os" == "debian" && "$os_version" -lt 10 ]]; then
	echo "Versão do anterior ao Debian 10 detectada, avisa o Guedao"
	exit
fi

if [[ "$os" == "centos" && "$os_version" -lt 8 ]]; then
	echo "Versão do anterior ao CentOS 8 detectada, avisa o Guedao"
	exit
fi

##########################################################
########### Instalando
##########################################################
echo "
Zabbix Agent installation vai começar"
# Ubuntu
if [[ "$os" = "ubuntu" ]]; then
	wget https://repo.zabbix.com/zabbix/5.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.4-1+ubuntu20.04_all.deb
	dpkg -i zabbix-release_5.4-1+ubuntu20.04_all.deb &&  apt-get update && apt-get install -y zabbix-agent 
	if [ $? -eq 0 ]; then
		echo "Nao foi possivel instalar o agente"
	else
		echo "Baixou chefia (O_O)"
	fi
# Debian
	elif [[ "$os" = "debian" ]]; then
		wget https://repo.zabbix.com/zabbix/5.4/debian/pool/main/z/zabbix-release/zabbix-release_5.4-1+debian10_all.deb
		dpkg -i zabbix-release_5.4-1+debian10_all.deb &&  apt-get update && apt-get install -y zabbix-agent
		if [ $? -eq 0 ]; then
			echo "Nao foi possivel instalar o agente"
		else
			echo "Baixou chefia (O_O)"
		fi
# Centos + Fedora
	elif [[ "$os" = "centos" ]]; then
		rpm -Uvh https://repo.zabbix.com/zabbix/5.4/rhel/8/x86_64/zabbix-release-5.4-1.el8.noarch.rpm
		dnf clean all && dnf install -y zabbix-agent 
		if [ $? -eq 0 ]; then
			echo "Nao foi possivel instalar o agente"
		else
			echo "Baixou chefia (O_O)"
		fi
	else
		echo "o de fedora n ta pronto ainda"
		#if [ $? -eq 0 ]; then
		#echo "Nao foi possivel instalar o agente"
		#else
		#	echo "Baixou chefia (O_O)"
		#fi
fi

RANDOMDIR=/tmp/$RANDOM
mkdir -p -v $RANDOMDIR
cd $RANDOMDIR
if [ $? -eq 0 ]; then
	echo "AGENT CRT" > zabbix_agent.crt
	echo "AGENT KEY" > zabbix_agent.key
	echo "CA CRT" > zabbix_ca.crt
	echo "CA KEY" > zabbix_ca.key
else
	echo "Diretorio randomico inacessivel"
	exit
fi

mkdir -p -v /etc/zabbix/cert/
if [ $? -eq 0 ]; then
    mv zabbix_* /etc/zabbix/cert/
	chmod 644 /etc/zabbix/cert/zabbix_*
else
	echo "Deu bigode pra copiar os certificados"
	exit
fi

stat /etc/zabbix/zabbix_agentd.conf
if [ $? -eq 0 ]; then
    sed -i 's/Server=127.0.0.1/#Server=127.0.0.1/gi' /etc/zabbix/zabbix_agentd.conf
	sed -i -r 's/[[:punct:]] ListenPort\=[[:digit:]]{5}/ListenPort\=10051/g' /etc/zabbix/zabbix_agentd.conf
	sed -i -r 's/^ServerActive\=127.0.0.1/ServerActive=noc.next4sec.com/g' /etc/zabbix/zabbix_agentd.conf
	sed -i -r 's/^^Hostname\=Zabbix server/Hostname==system.hostname/g' /etc/zabbix/zabbix_agentd.conf
	echo "
TLSConnect=cert
TLSAccept=cert
TLSCAFile=/etc/zabbix/cert/zabbix_ca.crt
TLSCertFile=/etc/zabbix/cert/zabbix_agent.crt
TLSKeyFile=/etc/zabbix/cert/zabbix_agent.key" >> /etc/zabbix/zabbix_agentd.conf
else
	echo "Arquivo /etc/zabbix/zabbix_agentd.conf inacessivel"
	exit
fi

/etc/init.d/zabbix-agent start
if [ $? -eq 0 ]; then
   systemctl enable zabbix-agent
else
   /etc/init.d/zabbix-agent restart
   systemctl enable zabbix-agent
fi
