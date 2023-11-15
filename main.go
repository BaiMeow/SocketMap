package main

import (
	"flag"
	"github.com/BaiMeow/SocketMap/config"
	"github.com/BaiMeow/SocketMap/iptables"
)

var (
	conf       string
	prefSource string
)

func main() {
	flag.StringVar(&conf, "c", "", "config file path")
	flag.StringVar(&prefSource, "s", "", "pref source ip")
	flag.Parse()
	config.Init(conf)
	iptables.Init(prefSource)
	for _, v := range config.Conf {
		iptables.Mapping(v.LocalPort, v.Remote, v.Protocol)
	}
}
