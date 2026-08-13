/* global axios */
import ApiClient from './ApiClient';

class SalesAPI extends ApiClient {
  constructor() {
    super('sales', { accountScoped: true });
  }

  summary({ since, until } = {}) {
    return axios.get(`${this.url}/summary`, { params: { since, until } });
  }
}

export default new SalesAPI();
