import Component from "@ember/component";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { inject as service } from "@ember/service";

export default Component.extend({
  tagName: "",
  dialog: service(),
  store: service(),

  @action
  async createApiKey() {
    try {
      const result = await ajax("/user-api-key/create", {
        type: "POST",
        data: {
          scopes: ["read", "write"] // 您可以修改这里以允许用户选择
        }
      });
      this.set("model", this.model.concat(result));
      this.dialog.alert(I18n.t("user_api_key.created"));
    } catch (error) {
      popupAjaxError(error);
    }
  },

  @action
  async revokeApiKey(apiKey) {
    try {
      await ajax(`/user-api-key/${apiKey.id}`, { type: "DELETE" });
      this.set("model", this.model.filter(key => key.id !== apiKey.id));
      this.dialog.alert(I18n.t("user_api_key.revoked"));
    } catch (error) {
      popupAjaxError(error);
    }
  }
});