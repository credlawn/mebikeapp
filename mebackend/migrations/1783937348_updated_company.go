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

		// remove field
		collection.Fields.RemoveById("number3045404147")

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(18, []byte(`{
			"autogeneratePattern": "",
			"help": "",
			"hidden": false,
			"id": "text783054703",
			"max": 0,
			"min": 0,
			"name": "pincode",
			"pattern": "",
			"presentable": false,
			"primaryKey": false,
			"required": false,
			"system": false,
			"type": "text"
		}`)); err != nil {
			return err
		}

		return app.Save(collection)
	}, func(app core.App) error {
		collection, err := app.FindCollectionByNameOrId("pbc_3740038821")
		if err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(8, []byte(`{
			"help": "",
			"hidden": false,
			"id": "number3045404147",
			"max": null,
			"min": null,
			"name": "pincode",
			"onlyInt": false,
			"presentable": false,
			"required": false,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		// remove field
		collection.Fields.RemoveById("text783054703")

		return app.Save(collection)
	})
}
