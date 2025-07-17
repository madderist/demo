package helloworld

import (
	"fmt"
	"net/http"

	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
)

// The init function is run by the framework on startup.
// It registers our HTTP function, "HelloWorld", with a URL path of "/"
func init() {
	functions.HTTP("HelloWorld", HelloWorld)
}

// HelloWorld is the entry point for the function.
// It's a standard http.HandlerFunc that writes "Hello, World!" to the response.
func HelloWorld(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "Hello, World!")
}
