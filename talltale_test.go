package talltale_test

import (
	"bytes"
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
	})

	Describe("GET /worlds", func() {

		var resp *http.Response
		var err error

		BeforeEach(func() {
			resp, err = http.Get(server.URL + "/worlds")
		})
		AfterEach(func() {
			if resp != nil && resp.Body != nil {
				resp.Body.Close()
			}
		})

		It("should return worlds", func() {
			var data []storage.World
			Expect(err).To(BeNil())
			Expect(json.NewDecoder(resp.Body).Decode(&data)).To(BeNil())

			Expect(data).To(HaveLen(1))
			w := data[0]
			Expect(w.ID).To(Equal("test"))
			Expect(w.Global.Title).To(Equal("Test World"))
			Expect(w.PlayerSeed.Location).To(Equal("start"))
		})
	})

	Describe("GET /worlds/{WORLD}", func() {
		var resp *http.Response
		var err error

		BeforeEach(func() {
			resp, err = http.Get(server.URL + "/worlds/test")
		})
		AfterEach(func() {
			if resp != nil && resp.Body != nil {
				resp.Body.Close()
			}
		})

		It("should return the test world", func() {
			var w storage.World
			Expect(err).To(BeNil())
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

	Describe("POST /worlds/{WORLD}/locations", func() {
		var locRequest editor.CreateLocationRequest
		var req bytes.Buffer
		BeforeEach(func() {
			locRequest = editor.CreateLocationRequest{
				ID:          "new-location",
				Name:        "New Location",
				Description: "This is something you have never seen before.",
			}
			req = bytes.Buffer{}
			json.NewEncoder(&req).Encode(locRequest)
		})
		It("should create a location", func() {
			resp, err := http.Post(server.URL+"/worlds/test/locations", "application/json", &req)
			Expect(err).To(BeNil())
			defer resp.Body.Close()
			var respContent bool
			Expect(json.NewDecoder(resp.Body).Decode(&respContent)).To(BeNil())
			Expect(respContent).To(BeTrue())
		})
		It("makes the location visible in the world", func() {
			resp, err := http.Post(server.URL+"/worlds/test/locations", "application/json", &req)
			Expect(err).To(BeNil())
			defer resp.Body.Close()

			resp, err = http.Get(server.URL + "/worlds/test")
			var w storage.World
			Expect(err).To(BeNil())
			defer resp.Body.Close()
			Expect(json.NewDecoder(resp.Body).Decode(&w)).To(BeNil())

			Expect(w.Locations).To(HaveLen(2))
			loc := w.Locations[locRequest.ID]
			Expect(loc.ID).To(Equal(locRequest.ID))
			Expect(loc.Name).To(Equal(locRequest.Name))
			Expect(loc.Description).To(Equal(locRequest.Description))
		})
	})

})
