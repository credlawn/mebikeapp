package pb_hooks

import (
	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
)

func RegisterAuthHooks(app *pocketbase.PocketBase) {
	app.OnRecordAuthRequest("users").BindFunc(func(e *core.RecordAuthRequestEvent) error {
		if !e.Record.GetBool("enable") {
			return apis.NewBadRequestError("Your account is disabled. Please contact your manager.", nil)
		}
		return e.Next()
	})
}
