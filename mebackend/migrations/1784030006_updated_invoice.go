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
		if err := collection.Fields.AddMarshaledJSONAt(34, []byte(`{
			"autogeneratePattern": "",
			"help": "",
			"hidden": false,
			"id": "text1019336455",
			"max": 0,
			"min": 0,
			"name": "party_customer_code",
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
		if err := collection.Fields.AddMarshaledJSONAt(35, []byte(`{
			"autogeneratePattern": "",
			"help": "",
			"hidden": false,
			"id": "text3101787475",
			"max": 0,
			"min": 0,
			"name": "party_partner_code",
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
		collection, err := app.FindCollectionByNameOrId("pbc_20342958")
		if err != nil {
			return err
		}

		// remove field
		collection.Fields.RemoveById("text1019336455")

		// remove field
		collection.Fields.RemoveById("text3101787475")

		return app.Save(collection)
	})
}
