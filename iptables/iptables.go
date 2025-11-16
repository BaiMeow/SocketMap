package iptables

import (
	"log"
	"net"
	"slices"
	"strconv"

	"github.com/coreos/go-iptables/iptables"
	"github.com/libp2p/go-netroute"
)

const (
	MARK      = "0x110"
	DNATCHAIN = "SOCKET_MAP_DNAT"
)

func Init(s string) {
	nr, err := netroute.New()
	if err != nil {
		log.Fatalln(err)
	}
	iface, _, src, err := nr.Route(net.ParseIP("1.1.1.1"))
	if err != nil {
		log.Fatalln(err)
	}
	publicEth := iface.Name

	inputIPs, _ := iface.Addrs()

	ipt, err := iptables.New()
	if err != nil {
		log.Fatalln(err)
	}

	chains, err := ipt.ListChains("nat")
	if err != nil {
		log.Fatalln(err)
	}

	if slices.Contains(chains, DNATCHAIN) {
		for _, ethIP := range inputIPs {
			err := ipt.DeleteIfExists("nat", "PREROUTING", "-i", publicEth, "-d", ethIP.(*net.IPNet).IP.String(), "-j", DNATCHAIN)
			if err != nil {
				return
			}
		}
		if err := ipt.ClearAndDeleteChain("nat", DNATCHAIN); err != nil {
			log.Fatalln(err)
		}
	}

	if err := ipt.NewChain("nat", DNATCHAIN); err != nil {
		log.Fatalln(err)
	}

	for _, ethIP := range inputIPs {
		if err := ipt.InsertUnique("nat", "PREROUTING", 1, "-i", publicEth, "-d", ethIP.(*net.IPNet).IP.String(), "-j", DNATCHAIN); err != nil {
			log.Fatalln(err)
		}
	}

	if err := ipt.DeleteIfExists("nat", "POSTROUTING", "-m", "mark", "--mark", MARK); err != nil {
		log.Fatalln(err)
	}

	if s == "" {
		if err := ipt.InsertUnique("nat", "POSTROUTING", 1, "-m", "mark", "--mark", MARK, "-j", "MASQUERADE"); err != nil {
			log.Fatalln(err)
		}
	} else {
		if err := ipt.InsertUnique("nat", "POSTROUTING", 1, "-m", "mark", "--mark", MARK, "-j", "SNAT", "--to-source", src.String()); err != nil {
			log.Fatalln(err)
		}
	}

}

func Mapping(localPort uint, remote string, protocol string) {
	ipt, err := iptables.New()
	if err != nil {
		log.Fatalln(err)
	}
	if err := ipt.AppendUnique("nat", DNATCHAIN, "-p", protocol, "--dport", strconv.Itoa(int(localPort)), "-j", "MARK", "--set-mark", MARK); err != nil {
		log.Fatalln(err)
	}
	if err := ipt.AppendUnique("nat", DNATCHAIN, "-p", protocol, "--dport", strconv.Itoa(int(localPort)), "-m", "mark", "--mark", MARK, "-j", "DNAT", "--to-destination", remote); err != nil {
		log.Fatalln(err)
	}
}
