/* global axios */
import ApiClient from './ApiClient';

class UazapiAPI extends ApiClient {
  constructor() {
    super('integrations/uazapi', { accountScoped: true });
  }

  setup(params) {
    return axios.post(this.url, params);
  }

  status(inboxId) {
    return axios.get(`${this.url}/status`, { params: { inbox_id: inboxId } });
  }

  disconnect(inboxId) {
    return axios.post(`${this.url}/disconnect`, { inbox_id: inboxId });
  }
}

export default new UazapiAPI();
