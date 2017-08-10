#!/bin/bash
# Dete:2017/05/09
# Description:创建和吊销openvpn证书
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
action=$1
vpn_user=$2
vpn_ip=139.224.a.a
ovpn_file=/tmp/$vpn_user.ovpn
expect_script=/data/script/vpn_expect

usage(){
	echo "Usage: $0 {build|revoke} username"
	exit 1
}

# 制作客户端证书
build_ovpn(){
	cat > $ovpn_file <<- EOF
	client
	dev tun
	proto udp
	remote $vpn_ip 1194
	resolv-retry infinite
	nobind
	persist-key
	persist-tun
	ns-cert-type server
	comp-lzo
	verb 3
	tls-auth [inline] 1
	EOF

	echo "<ca>" >> $ovpn_file
	cat keys/ca.crt >> $ovpn_file
	echo "</ca>" >> $ovpn_file
	
	echo "<cert>" >> $ovpn_file
	sed -n '/-----BEGIN/,/-----END/p' keys/$vpn_user.crt >> $ovpn_file
	echo -e "</cert>" >> $ovpn_file
	
	echo "<key>" >> $ovpn_file
	cat keys/$vpn_user.key >> $ovpn_file
	echo "</key>" >> $ovpn_file
	
	echo "<tls-auth>" >> $ovpn_file
	cat keys/ta.key >> $ovpn_file
	echo "</tls-auth>" >> $ovpn_file
}

# 判断脚本参数个数
[ "$#" -ne 2 ] && {
	echo "Wrong number of argvs,it must be two."
	usage
}

# 判断vpn_ip是否正确
! ip -4 addr | grep -q "$vpn_ip" && {
	echo "Ip:$vpn_ip not found on local machine."
	exit 1
}

case $action in
	build)
		# 检测vpn环境
		cd /usr/share/easy-rsa/2.0
		source vars &> /dev/null
		[[ -f keys/$vpn_user.crt || -f keys/$vpn_user.key ]] && {
			echo "User $vpn_user already exist."
			exit 1
		}
		[[ ! -f keys/ca.crt || ! -f keys/server.key || ! -f keys/dh2048.pem || ! -f keys/ta.key ]] && {
			echo "File keys/ca.crt or keys/ta.key not found."
			echo "Pls run ./build-ca and ./build-key-server server and ./build-dh and openvpn --genkey --secret keys/ta.key first."
			exit 1
		}

		# 检查是否已安装expect
		rpm -q expect &> /dev/null || {
			echo "Pls install expect first."
			exit 1
		}

		[ ! -f $expect_script ] && {
			echo "Script:$expect_script not found."
			exit 1
		}
		
		# 开始制作证书
		$expect_script $vpn_user &> /dev/null
		build_ovpn
		echo "Build $vpn_user key success."
		echo "Download the file $ovpn_file to your client computer"
		;;
	revoke)
		# 吊销证书
		cd /usr/share/easy-rsa/2.0
		source ./vars &> /dev/null
		./revoke-full $vpn_user
		\cp keys/crl.pem /etc/openvpn/
		rm keys/$vpn_user* -f
		rm $ovpn_file -f
		;;
	*)
		echo "Undefine action"
		usage
		;;
esac
