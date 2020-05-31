package talltale

import (
	"encoding/json"
	"net/http"
)

type renderer interface{ render(rw http.ResponseWriter) }

type requestError struct {
	error
}

type serverError struct {
	error
}

func (e requestError) render(rw http.ResponseWriter) {
	rw.WriteHeader(http.StatusBadRequest)
	json.NewEncoder(rw).Encode(map[string]interface{}{"error": e.error.Error()})
}

func (e serverError) render(rw http.ResponseWriter) {
	rw.WriteHeader(http.StatusInternalServerError)
	json.NewEncoder(rw).Encode(map[string]interface{}{"error": e.error.Error()})
}
