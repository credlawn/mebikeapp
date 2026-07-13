package main

import (
	"log"

	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/plugins/migratecmd"
	"mepb/pb_hooks"

	_ "mepb/migrations"
)

func main() {
	app := pocketbase.New()

	migratecmd.MustRegister(app, app.RootCmd, migratecmd.Config{
		Automigrate:  true,
		TemplateLang: migratecmd.TemplateLangGo,
	})

	pb_hooks.RegisterAuthHooks(app)
	pb_hooks.RegisterInvoiceHooks(app)

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}
