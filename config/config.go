package config

import (
	"fmt"
	"github.com/spf13/viper"
	"log"
)

type SocketMaping struct {
	LocalPort uint   `yaml:"local_port"`
	Remote    string `yaml:"remote"`
	Protocol  string `yaml:"protocol"`
}

type Config map[string]SocketMaping

var Conf Config

func Init(filepath string) {
	if filepath != "" {
		viper.SetConfigFile(filepath)
		fmt.Println("Loading from ", filepath)
	} else {
		viper.SetConfigFile("/etc/socketMap.yaml")
		fmt.Println("Loading from", "/etc/socketMap.yaml")
	}

	err := viper.ReadInConfig()
	if err != nil {
		log.Fatalln(err)
	}
	conf := make(map[string]SocketMaping)
	for mp := range viper.AllSettings() {
		conf[mp] = SocketMaping{
			LocalPort: viper.GetUint(mp + ".local_port"),
			Remote:    viper.GetString(mp + ".remote"),
			Protocol:  viper.GetString(mp + ".protocol"),
		}
	}
	Conf = conf
}
