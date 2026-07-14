package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
	m.Register(func(app core.App) error {
		collection, err := app.FindCollectionByNameOrId("pbc_20342958")
		if err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(32, []byte(`{
			"help": "",
			"hidden": false,
			"id": "file2785129551",
			"maxSelect": 0,
			"maxSize": 0,
			"mimeTypes": null,
			"name": "invoice_pdf",
			"presentable": false,
			"protected": false,
			"required": false,
			"system": false,
			"thumbs": null,
			"type": "file"
		}`)); err != nil {
			return err
		}

		return app.Save(collection)
	}, func(app core.App) error {
		collection, err := app.FindCollectionByNameOrId("pbc_20342958")
		if err != nil {
			return err
		}

		// remove field
		collection.Fields.RemoveById("file2785129551")

		return app.Save(collection)
	})
}
