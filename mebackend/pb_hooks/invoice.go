package pb_hooks

import (
	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/core"
)

func RegisterInvoiceHooks(app *pocketbase.PocketBase) {
	app.OnRecordCreate("invoice").BindFunc(func(e *core.RecordEvent) error {
		if err := e.Next(); err != nil {
			return err
		}
		if e.Record.GetString("status") != "confirmed" {
			return nil
		}
		return lockAllConfirmedExcept(e.App, e.Record.Id)
	})

	app.OnRecordUpdate("invoice").BindFunc(func(e *core.RecordEvent) error {
		old, _ := e.App.FindRecordById("invoice", e.Record.Id)
		if old == nil || old.GetString("invoice_no") != "" {
			return e.Next()
		}
		if e.Record.GetString("invoice_no") == "" {
			return e.Next()
		}
		if err := e.Next(); err != nil {
			return err
		}
		return lockAllConfirmedExcept(e.App, e.Record.Id)
	})
}

func lockAllConfirmedExcept(app core.App, excludeId string) error {
	records, err := app.FindRecordsByFilter(
		"invoice",
		"invoice_no != '' && locked = false && id != {:id}",
		"", -1, 0,
		map[string]any{"id": excludeId},
	)
	if err != nil {
		return nil
	}
	for _, r := range records {
		r.Set("locked", true)
		app.Save(r)
	}
	return nil
}
