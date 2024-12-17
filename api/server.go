package main

import (
	"net/http"
)

func main() {
	http.HandleFunc("/", Healthz)
	err := http.ListenAndServe(":3333", nil)
	if err != nil {
		return
	}
}

func Healthz(w http.ResponseWriter, r *http.Request) {
	_, _ = w.Write([]byte("ok 🔥🔥🚒🚒"))
}
