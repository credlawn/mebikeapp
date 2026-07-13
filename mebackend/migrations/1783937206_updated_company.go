package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
	m.Register(func(app core.App) error {
		collection, err := app.FindCollectionByNameOrId("pbc_3740038821")
		if err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(16, []byte(`{
			"autogeneratePattern": "",
			"help": "",
			"hidden": false,
			"id": "text1140330741",
			"max": 0,
			"min": 0,
			"name": "account_no",
			"pattern": "",
			"presentable": false,
			"primaryKey": false,
			"required": false,
			"system": false,
			"type": "text"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(17, []byte(`{
			"autogeneratePattern": "",
			"help": "",
			"hidden": false,
			"id": "text3146128159",
			"max": 0,
			"min": 0,
			"name": "branch",
			"pattern": "",
			"presentable": false,
			"primaryKey": false,
			"required": false,
			"system": false,
			"type": "text"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(18, []byte(`{
			"help": "",
			"hidden": false,
			"id": "file3834550803",
			"maxSelect": 0,
			"maxSize": 0,
			"mimeTypes": null,
			"name": "logo",
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
		collection, err := app.FindCollectionByNameOrId("pbc_3740038821")
		if err != nil {
			return err
		}

		// remove field
		collection.Fields.RemoveById("text1140330741")

		// remove field
		collection.Fields.RemoveById("text3146128159")

		// remove field
		collection.Fields.RemoveById("file3834550803")

		return app.Save(collection)
	})
}
