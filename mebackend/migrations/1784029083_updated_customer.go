package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
	m.Register(func(app core.App) error {
		collection, err := app.FindCollectionByNameOrId("pbc_3245856272")
		if err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(18, []byte(`{
			"autogeneratePattern": "",
			"help": "",
			"hidden": false,
			"id": "text2476065779",
			"max": 0,
			"min": 0,
			"name": "customer_id",
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
		collection, err := app.FindCollectionByNameOrId("pbc_3245856272")
		if err != nil {
			return err
		}

		// remove field
		collection.Fields.RemoveById("text2476065779")

		return app.Save(collection)
	})
}
