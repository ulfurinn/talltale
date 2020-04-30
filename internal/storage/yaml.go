package storage

import (
	"io/ioutil"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v2"
)

type YAML struct {
	Root string
}

func (y YAML) Enum() (ids []string, err error) {
	var f *os.File
	if f, err = os.Open(y.Root); err != nil {
		return
	}
	defer f.Close()

	var dirs []string
	if dirs, err = f.Readdirnames(-1); err != nil {
		return
	}
	for _, dir := range dirs {
		if _, err := os.Stat(y.filepath(dir)); err == nil {
			ids = append(ids, dir)
		}
	}
	return
}

func (y YAML) Save(w World) (err error) {
	var f *os.File
	if f, err = os.Create(y.filepath(w.ID)); err != nil {
		return
	}
	defer f.Close()
	encoder := yaml.NewEncoder(f)
	err = encoder.Encode(w)
	return
}

func (y YAML) Load(id string) (w World, err error) {
	file := y.filepath(id)
	var yml []byte
	if yml, err = ioutil.ReadFile(file); err != nil {
		return
	}
	if err = yaml.Unmarshal(yml, &w); err != nil {
		return
	}
	w.ID = id
	return
}

func (y YAML) filepath(id string) string {
	return filepath.Join(y.Root, id, "world.yml")
}
