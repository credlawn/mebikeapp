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
		if err := collection.Fields.AddMarshaledJSONAt(19, []byte(`{
			"autogeneratePattern": "",
			"help": "",
			"hidden": false,
			"id": "text2756634359",
			"max": 0,
			"min": 0,
			"name": "contact_person",
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
		if err := collection.Fields.AddMarshaledJSONAt(20, []byte(`{
			"autogeneratePattern": "",
			"help": "",
			"hidden": false,
			"id": "text1620380932",
			"max": 0,
			"min": 0,
			"name": "mobile_no",
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
		if err := collection.Fields.AddMarshaledJSONAt(21, []byte(`{
			"exceptDomains": null,
			"help": "",
			"hidden": false,
			"id": "email3885137012",
			"name": "email",
			"onlyDomains": null,
			"presentable": false,
			"required": false,
			"system": false,
			"type": "email"
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
		collection.Fields.RemoveById("text2756634359")

		// remove field
		collection.Fields.RemoveById("text1620380932")

		// remove field
		collection.Fields.RemoveById("email3885137012")

		return app.Save(collection)
	})
}
