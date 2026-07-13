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

		// update field
		if err := collection.Fields.AddMarshaledJSONAt(30, []byte(`{
			"cascadeDelete": false,
			"collectionId": "pbc_3245856272",
			"help": "",
			"hidden": false,
			"id": "relation2476065779",
			"maxSelect": 0,
			"minSelect": 0,
			"name": "customer_id",
			"presentable": true,
			"required": false,
			"system": false,
			"type": "relation"
		}`)); err != nil {
			return err
		}

		return app.Save(collection)
	}, func(app core.App) error {
		collection, err := app.FindCollectionByNameOrId("pbc_20342958")
		if err != nil {
			return err
		}

		// update field
		if err := collection.Fields.AddMarshaledJSONAt(30, []byte(`{
			"cascadeDelete": false,
			"collectionId": "pbc_3245856272",
			"help": "",
			"hidden": false,
			"id": "relation2476065779",
			"maxSelect": 0,
			"minSelect": 0,
			"name": "customer_id",
			"presentable": false,
			"required": false,
			"system": false,
			"type": "relation"
		}`)); err != nil {
			return err
		}

		return app.Save(collection)
	})
}
