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
		if e.Record.GetString("status") == "confirmed" {
			if qNo := e.Record.GetString("quotation_no"); qNo != "" {
				quotes, _ := app.FindRecordsByFilter(
					"invoice",
					"invoice_no = {:qNo} && mode = 'quotation'",
					"", 1, 0,
					map[string]any{"qNo": qNo},
				)
				if len(quotes) > 0 {
					quotes[0].Set("status", "billed")
					app.Save(quotes[0])
				}
			}
		}

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
		"invoice_no != '' && locked = false && mode = 'invoice' && id != {:id}",
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
