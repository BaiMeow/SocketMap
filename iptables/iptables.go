package iptables

import (
	"github.com/coreos/go-iptables/iptables"
	"github.com/yaklang/yaklang/common/utils/netutil"
	"log"
	"strconv"
	"time"
)

var source string
var mark = "0x110"
var defaultEthernet = "eth0"

func Init(s string) {
	iface, _, src, err := netutil.Route(time.Second*3, "1.1.1.1")
	if err != nil {
		log.Fatalln(err)
	}

	defaultEthernet = iface.Name
	if s != "" {
		source = s
	} else {
		source = src.String()
	}

	ipt, err := iptables.New()
	if err != nil {
		log.Fatalln(err)
	}

	if err := ipt.DeleteIfExists("nat", "SOCKET_MAP_DNAT"); err != nil {
		log.Fatalln(err)
	}

	if err := ipt.NewChain("nat", "SOCKET_MAP_DNAT"); err != nil {
		log.Fatalln(err)
	}

	if err := ipt.InsertUnique("nat", "PREROUTING", 1, "-i", defaultEthernet, "-j", "SOCKET_MAP_DNAT"); err != nil {
		log.Fatalln(err)
	}

	if err := ipt.DeleteIfExists("nat", "SOCKET_MAP_SNAT"); err != nil {
		log.Fatalln(err)
	}

	if err := ipt.NewChain("nat", "SOCKET_MAP_SNAT"); err != nil {
		log.Fatalln(err)
	}

	if err := ipt.InsertUnique("nat", "POSTROUTING", 1, "-i", defaultEthernet, "-j", "SOCKET_MAP_SNAT"); err != nil {
		log.Fatalln(err)
	}
}

func Mapping(localPort uint, remote string, protocol string) {
	ipt, err := iptables.New()
	if err != nil {
		log.Fatalln(err)
	}
	if err := ipt.AppendUnique("nat", "SOCKET_MAP_DNAT", "-p", protocol, "-j", "MARK", "--set-mark", mark); err != nil {
		log.Fatalln(err)
	}
	if err := ipt.AppendUnique("nat", "SOCKET_MAP_DNAT", "-p", protocol, "--dport", strconv.Itoa(int(localPort)), "--mark", mark, "-j", "DNAT", "--to-destination", remote); err != nil {
		log.Fatalln(err)
	}
	if err := ipt.AppendUnique("nat", "SOCKET_MAP_SNAT", "--mark", mark, "-j", "SNAT", "--to-source", source); err != nil {
		log.Fatalln(err)
	}
}
