package talltale_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/ulfurinn/talltale/internal/editor"
	"github.com/ulfurinn/talltale/internal/storage"
)

var _ = Describe("Editor", func() {

	var storer testStorer
	var server *httptest.Server

	var resp *http.Response
	var err error

	BeforeSuite(func() {
		storer = testStorer{worlds: make(map[string]storage.World)}
		storage.Storage = &storer
	})

	BeforeEach(func() {
		storage.Storage.Save(testWorld())
		storage.Load()
		server = httptest.NewServer(editor.Mux())
	})

	AfterEach(func() {
		server.Close()
		if resp != nil && resp.Body != nil {
			resp.Body.Close()
		}
	})

	Describe("GET /worlds", func() {

		BeforeEach(func() {
			resp, err = http.Get(server.URL + "/worlds")
		})

		It("should succeed", func() {
			Expect(err).To(BeNil())
		})

		It("should return worlds", func() {
			var data []storage.World
			Expect(json.NewDecoder(resp.Body).Decode(&data)).To(BeNil())

			Expect(data).To(HaveLen(1))
			w := data[0]
			Expect(w.ID).To(Equal("test"))
			Expect(w.Global.Title).To(Equal("Test World"))
			Expect(w.PlayerSeed.Location).To(Equal("start"))
		})
	})

	Describe("GET /worlds/{ID}", func() {
		BeforeEach(func() {
			resp, err = http.Get(server.URL + "/worlds/test")
		})

		It("should succeed", func() {
			Expect(err).To(BeNil())
		})

		It("should return the test world", func() {
			var w storage.World
			Expect(json.NewDecoder(resp.Body).Decode(&w)).To(BeNil())

			Expect(w.ID).To(Equal("test"))
			Expect(w.Global.Title).To(Equal("Test World"))
			Expect(w.PlayerSeed.Location).To(Equal("start"))

			Expect(w.Locations).To(HaveLen(1))
			loc := w.Locations["start"]
			Expect(loc.ID).To(Equal("start"))
			Expect(loc.Name).To(Equal("Start"))
		})

	})

})
