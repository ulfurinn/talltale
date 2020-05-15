package talltale_test

import (
	"bytes"
	"encoding/json"
	"io"
	"io/ioutil"
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

	getWorld := func(id string) (w storage.World) {
		resp, err := http.Get(server.URL + "/worlds/" + id)
		Expect(err).To(BeNil())
		Expect(json.NewDecoder(resp.Body).Decode(&w)).To(BeNil())
		resp.Body.Close()
		return
	}

	makeReader := func(data interface{}) *bytes.Reader {
		j, _ := json.Marshal(data)
		return bytes.NewReader(j)
	}

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

			Expect(loc.Encounters).To(HaveLen(1))
			enc := loc.Encounters[0]
			Expect(enc.ID).To(Equal("encounter-1"))
			Expect(enc.Name).To(Equal("Encounter 1"))
			Expect(enc.Description).To(Equal("This is an encounter"))
			Expect(enc.Story).To(Equal("This is what happened when you opened the door."))

			Expect(enc.Conditions).To(HaveLen(1))
			Expect(enc.Conditions).To(HaveKey("strong"))
			cond := enc.Conditions["strong"]
			Expect(cond.StatCondition).To(HaveLen(1))
			Expect(cond.StatCondition).To(HaveKey("strength"))
			strength := cond.StatCondition["strength"]
			Expect(strength.Min).To(PointTo(5))
			Expect(strength.Max).To(BeNil())
			Expect(strength.Hide).To(BeFalse())
		})

	})

	Describe("POST /worlds/{WORLD}/locations", func() {
		request := func() editor.CreateLocationRequest {
			return editor.CreateLocationRequest{
				ID:          "new-location",
				Name:        "New Location",
				Description: "This is something you have never seen before.",
			}
		}

		It("should create a location", func() {
			resp, err := http.Post(server.URL+"/worlds/test/locations", "application/json", makeReader(request()))

			Expect(err).To(BeNil())
			Expect(resp.StatusCode).To(Equal(http.StatusCreated))

			var respContent bool
			Expect(json.NewDecoder(resp.Body).Decode(&respContent)).To(BeNil())
			resp.Body.Close()

			Expect(respContent).To(BeTrue())
		})
		It("makes the location visible in the world", func() {
			req := request()
			resp, err := http.Post(server.URL+"/worlds/test/locations", "application/json", makeReader(req))
			Expect(err).To(BeNil())
			resp.Body.Close()

			w := getWorld("test")

			Expect(w.Locations).To(HaveLen(2))
			loc := w.Locations[req.ID]
			Expect(loc.ID).To(Equal(req.ID))
			Expect(loc.Name).To(Equal(req.Name))
			Expect(loc.Description).To(Equal(req.Description))
		})
		It("rejects attempts to create the same location twice", func() {
			reader := makeReader(request())
			resp, err := http.Post(server.URL+"/worlds/test/locations", "application/json", reader)
			Expect(err).To(BeNil())
			Expect(resp.StatusCode).To(Equal(http.StatusCreated))
			resp.Body.Close()

			reader.Seek(0, io.SeekStart)

			resp, err = http.Post(server.URL+"/worlds/test/locations", "application/json", reader)
			Expect(err).To(BeNil())
			Expect(resp.StatusCode).To(Equal(http.StatusConflict))
			resp.Body.Close()
		})
	})

	Describe("PATCH /worlds/{WORLD}/locations/{LOCATION}", func() {
		It("should update the name", func() {
			req := editor.PatchLocationRequest{
				Name: pstring("Beginning"),
			}
			httpreq, _ := http.NewRequest("PATCH", server.URL+"/worlds/test/locations/start", makeReader(req))
			httpreq.Header.Set("Content-Type", "application/json")
			resp, err := http.DefaultClient.Do(httpreq)
			Expect(err).To(BeNil())
			Expect(resp.StatusCode).To(Equal(http.StatusOK))
			resp.Body.Close()

			w := getWorld("test")
			loc := w.Locations["start"]
			Expect(loc.Name).To(Equal("Beginning"))
			Expect(loc.Description).To(Equal("It all began here."))
		})
		It("should update the description", func() {
			req := editor.PatchLocationRequest{
				Description: pstring("It all started here."),
			}
			httpreq, _ := http.NewRequest("PATCH", server.URL+"/worlds/test/locations/start", makeReader(req))
			httpreq.Header.Set("Content-Type", "application/json")
			resp, err := http.DefaultClient.Do(httpreq)
			Expect(err).To(BeNil())
			Expect(resp.StatusCode).To(Equal(http.StatusOK))
			resp.Body.Close()

			w := getWorld("test")
			loc := w.Locations["start"]
			Expect(loc.Name).To(Equal("Start"))
			Expect(loc.Description).To(Equal("It all started here."))
		})
		It("should update all fields together", func() {
			req := editor.PatchLocationRequest{
				Name:        pstring("Beginning"),
				Description: pstring("It all started here."),
			}
			httpreq, _ := http.NewRequest("PATCH", server.URL+"/worlds/test/locations/start", makeReader(req))
			httpreq.Header.Set("Content-Type", "application/json")
			resp, err := http.DefaultClient.Do(httpreq)
			Expect(err).To(BeNil())
			Expect(resp.StatusCode).To(Equal(http.StatusOK))
			resp.Body.Close()

			w := getWorld("test")
			loc := w.Locations["start"]
			Expect(loc.Name).To(Equal("Beginning"))
			Expect(loc.Description).To(Equal("It all started here."))
		})
	})

	Describe("POST /worlds/{WORLD}/locations/{LOCATION}/encounters", func() {
		It("should create an encounter", func() {
			req := editor.CreateEncounterRequest{
				ID:          "encounter-2",
				Name:        "Encounter 2",
				Description: "This is another encounter",
				Story:       "Isn't this door much better?",
			}
			resp, err := http.Post(server.URL+"/worlds/test/locations/start/encounters", "application/json", makeReader(req))
			Expect(err).To(BeNil())
			Expect(resp.StatusCode).To(Equal(http.StatusCreated))
			io.Copy(ioutil.Discard, resp.Body)
			resp.Body.Close()

			w := getWorld("test")
			loc := w.Locations["start"]
			var found bool
			for _, e := range loc.Encounters {
				if e.ID == "encounter-2" {
					found = true
					Expect(e.Name).To(Equal("Encounter 2"))
					Expect(e.Description).To(Equal("This is another encounter"))
					Expect(e.Story).To(Equal("Isn't this door much better?"))
					Expect(e.Conditions).To(BeEmpty())
					Expect(e.Choices).To(BeEmpty())
				}
			}
			Expect(found).To(BeTrue())
		})
	})

})
