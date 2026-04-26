package main

import (
	"log"

	"github.com/pocketbase/pocketbase"
	"mepb/pb_hooks"
)

func main() {
	app := pocketbase.New()

	// Register hooks from the separate package
	pb_hooks.RegisterAuthHooks(app)

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}
