package config

import (
	"github.com/spf13/viper"
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
	} else {
		viper.SetConfigFile("/etc/socketMap.yaml")
	}

	viper.ReadInConfig()
	conf := make(map[string]SocketMaping)
	mps := viper.GetStringMap("")
	for mp := range mps {
		conf[mp] = SocketMaping{
			LocalPort: viper.GetUint(mp + ".local_port"),
			Remote:    viper.GetString(mp + ".remote"),
			Protocol:  viper.GetString(mp + ".protocol"),
		}
	}
	Conf = conf
}
