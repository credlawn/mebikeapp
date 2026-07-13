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
		if err := collection.Fields.AddMarshaledJSONAt(9, []byte(`{
			"autogeneratePattern": "",
			"help": "",
			"hidden": false,
			"id": "text2228756930",
			"max": 0,
			"min": 0,
			"name": "pan_no",
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
		if err := collection.Fields.AddMarshaledJSONAt(10, []byte(`{
			"autogeneratePattern": "",
			"help": "",
			"hidden": false,
			"id": "text3213844728",
			"max": 0,
			"min": 0,
			"name": "gst_no",
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
		if err := collection.Fields.AddMarshaledJSONAt(11, []byte(`{
			"autogeneratePattern": "",
			"help": "",
			"hidden": false,
			"id": "text3824597342",
			"max": 0,
			"min": 0,
			"name": "state_code",
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
		if err := collection.Fields.AddMarshaledJSONAt(12, []byte(`{
			"autogeneratePattern": "",
			"help": "",
			"hidden": false,
			"id": "text2508287611",
			"max": 0,
			"min": 0,
			"name": "gst_filing_type",
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
		if err := collection.Fields.AddMarshaledJSONAt(13, []byte(`{
			"help": "",
			"hidden": false,
			"id": "date1947846871",
			"max": "",
			"min": "",
			"name": "gst_registration_date",
			"presentable": false,
			"required": false,
			"system": false,
			"type": "date"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(14, []byte(`{
			"autogeneratePattern": "",
			"help": "",
			"hidden": false,
			"id": "text4098043016",
			"max": 0,
			"min": 0,
			"name": "bank_name",
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
		if err := collection.Fields.AddMarshaledJSONAt(15, []byte(`{
			"autogeneratePattern": "",
			"help": "",
			"hidden": false,
			"id": "text3217001137",
			"max": 0,
			"min": 0,
			"name": "ifsc_code",
			"pattern": "",
			"presentable": false,
			"primaryKey": false,
			"required": false,
			"system": false,
			"type": "text"
		}`)); err != nil {
			return err
		}

		// update field
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

		return app.Save(collection)
	}, func(app core.App) error {
		collection, err := app.FindCollectionByNameOrId("pbc_3740038821")
		if err != nil {
			return err
		}

		// remove field
		collection.Fields.RemoveById("text2228756930")

		// remove field
		collection.Fields.RemoveById("text3213844728")

		// remove field
		collection.Fields.RemoveById("text3824597342")

		// remove field
		collection.Fields.RemoveById("text2508287611")

		// remove field
		collection.Fields.RemoveById("date1947846871")

		// remove field
		collection.Fields.RemoveById("text4098043016")

		// remove field
		collection.Fields.RemoveById("text3217001137")

		// update field
		if err := collection.Fields.AddMarshaledJSONAt(8, []byte(`{
			"help": "",
			"hidden": false,
			"id": "number3045404147",
			"max": null,
			"min": null,
			"name": "pin",
			"onlyInt": false,
			"presentable": false,
			"required": false,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		return app.Save(collection)
	})
}
