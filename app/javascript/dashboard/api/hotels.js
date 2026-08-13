/* global axios */
import ApiClient from './ApiClient';

class HotelsAPI extends ApiClient {
  constructor() {
    super('hotels', { accountScoped: true });
  }

  assignAgents(hotelId, userIds) {
    return axios.post(`${this.url}/${hotelId}/assign_agents`, {
      user_ids: userIds,
    });
  }
}

export default new HotelsAPI();
