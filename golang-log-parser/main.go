package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"

	"github.com/gorilla/websocket"
)

type LogLine struct {
	Date float64 `json:"date"`
	Log  string  `json:"log"`
}

type Nginx struct {
	Time          string  `json:"time"`
	RemoteAddr    string  `json:"remote_addr"`
	XForwardedFor string  `json:"x_forward_for"`
	RequestId     string  `json:"request_id"`
	RemoteUser    string  `json:"remote_user"`
	BytesSent     string  `json:"bytes_sent"`
	RequestTime   string  `json:"request_time"`
	Status        int     `json:"status"`
	VHost         string  `json:"vhost"`
	RequestProto  string  `json:"request_proto"`
	Path          string  `json:"path"`
	RequestQuery  string  `json:"request_query"`
	RequestLength string  `json:"request_length"`
	Duration      float32 `json:"duration"`
	Method        string  `json:"method"`
	HTTPReferee   string  `json:"http_referrer"`
	HTTPUserAgent string  `json:"http_user_agent"`
}

func unmarshalMessage(msg []byte) {
	incoming := []LogLine{}
	if err := json.Unmarshal(msg, &incoming); err != nil {
		log.Println("Error unmarshaling msg", err)
	}

	for i := range incoming {
		nginx := Nginx{}
		filtered := strings.Split(incoming[i].Log, "Z stdout F ")[1]

		if err := json.Unmarshal([]byte(filtered), &nginx); err != nil {
			log.Println("Error unmarshaling filtered", err)
		}

		log.Printf("%#v", nginx)
	}
}

var upgrader = websocket.Upgrader{} // use default options

func socketHandler(w http.ResponseWriter, r *http.Request) {
	// Upgrade our raw HTTP connection to a websocket based one
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Print("Error during connection upgradation:", err)
		return
	}
	defer conn.Close()

	// The event loop
	for {
		messageType, message, err := conn.ReadMessage()
		if err != nil {
			log.Println("Error during message reading:", err)
			break
		}
		//log.Printf("Received: %s", message)
		unmarshalMessage(message)
		err = conn.WriteMessage(messageType, message)
		if err != nil {
			log.Println("Error during message writing:", err)
			break
		}
	}
}

func home(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Index Page")
}

func main() {
	http.HandleFunc("/socket", socketHandler)
	http.HandleFunc("/", home)
	log.Fatal(http.ListenAndServe("0.0.0.0:8080", nil))
}
