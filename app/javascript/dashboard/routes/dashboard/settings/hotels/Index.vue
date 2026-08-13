<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import HotelsAPI from 'dashboard/api/hotels';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'shared/components/Spinner.vue';

const { t } = useI18n();
const store = useStore();

const hotels = ref([]);
const isLoading = ref(false);
const newHotelName = ref('');
const isCreating = ref(false);
const deleteCandidateId = ref(null);

const agents = useMapGetter('agents/getAgents');
const agentList = computed(() => agents.value || []);

const fetchHotels = async () => {
  isLoading.value = true;
  try {
    const { data } = await HotelsAPI.get();
    hotels.value = data;
  } catch (error) {
    useAlert(t('HOTELS_SETTINGS.FETCH_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const createHotel = async () => {
  if (!newHotelName.value.trim()) return;
  isCreating.value = true;
  try {
    await HotelsAPI.create({ name: newHotelName.value.trim() });
    newHotelName.value = '';
    await fetchHotels();
    useAlert(t('HOTELS_SETTINGS.ADD.SUCCESS'));
  } catch (error) {
    useAlert(error?.response?.data?.message || t('HOTELS_SETTINGS.ADD.ERROR'));
  } finally {
    isCreating.value = false;
  }
};

const toggleActive = async hotel => {
  try {
    await HotelsAPI.update(hotel.id, { active: !hotel.active });
    hotel.active = !hotel.active;
  } catch (error) {
    useAlert(t('HOTELS_SETTINGS.UPDATE_ERROR'));
  }
};

const isAssigned = (hotel, agentId) => hotel.user_ids.includes(agentId);

const toggleAgent = async (hotel, agentId) => {
  const userIds = isAssigned(hotel, agentId)
    ? hotel.user_ids.filter(id => id !== agentId)
    : [...hotel.user_ids, agentId];
  try {
    const { data } = await HotelsAPI.assignAgents(hotel.id, userIds);
    hotel.user_ids = data.user_ids;
  } catch (error) {
    useAlert(t('HOTELS_SETTINGS.UPDATE_ERROR'));
  }
};

const removeHotel = async hotel => {
  if (deleteCandidateId.value !== hotel.id) {
    deleteCandidateId.value = hotel.id;
    return;
  }
  try {
    await HotelsAPI.delete(hotel.id);
    hotels.value = hotels.value.filter(item => item.id !== hotel.id);
    useAlert(t('HOTELS_SETTINGS.DELETE.SUCCESS'));
  } catch (error) {
    useAlert(t('HOTELS_SETTINGS.DELETE.ERROR'));
  } finally {
    deleteCandidateId.value = null;
  }
};

onMounted(() => {
  fetchHotels();
  store.dispatch('agents/get');
});
</script>

<template>
  <div class="flex flex-col gap-6 p-6 w-full">
    <BaseSettingsHeader
      :title="t('HOTELS_SETTINGS.HEADER')"
      :description="t('HOTELS_SETTINGS.DESCRIPTION')"
      feature-name="hotels"
    />

    <form class="flex gap-3 items-center max-w-xl" @submit.prevent="createHotel">
      <input
        v-model="newHotelName"
        type="text"
        :placeholder="t('HOTELS_SETTINGS.ADD.PLACEHOLDER')"
        class="flex-1 reset-base h-10 px-3 rounded-lg border border-n-strong bg-n-alpha-black2 text-n-slate-12 outline-none focus:border-n-brand"
      />
      <Button
        type="submit"
        solid
        blue
        :is-loading="isCreating"
        :label="t('HOTELS_SETTINGS.ADD.BUTTON')"
      />
    </form>

    <div v-if="isLoading" class="flex justify-center py-10">
      <Spinner />
    </div>

    <p v-else-if="!hotels.length" class="text-n-slate-11">
      {{ t('HOTELS_SETTINGS.EMPTY') }}
    </p>

    <div v-else class="flex flex-col gap-4">
      <div
        v-for="hotel in hotels"
        :key="hotel.id"
        class="flex flex-col gap-3 p-4 rounded-xl border border-n-weak bg-n-solid-2"
      >
        <div class="flex items-center justify-between gap-3">
          <div class="flex items-center gap-3">
            <span class="text-base font-medium text-n-slate-12">
              {{ hotel.name }}
            </span>
            <span
              class="text-xs px-2 py-0.5 rounded-full"
              :class="
                hotel.active
                  ? 'bg-n-teal-9/15 text-n-teal-11'
                  : 'bg-n-slate-9/15 text-n-slate-11'
              "
            >
              {{
                hotel.active
                  ? t('HOTELS_SETTINGS.ACTIVE')
                  : t('HOTELS_SETTINGS.INACTIVE')
              }}
            </span>
          </div>
          <div class="flex items-center gap-2">
            <Button
              ghost
              slate
              sm
              :label="
                hotel.active
                  ? t('HOTELS_SETTINGS.DEACTIVATE')
                  : t('HOTELS_SETTINGS.ACTIVATE')
              "
              @click="toggleActive(hotel)"
            />
            <Button
              ghost
              ruby
              sm
              :label="
                deleteCandidateId === hotel.id
                  ? t('HOTELS_SETTINGS.DELETE.CONFIRM')
                  : t('HOTELS_SETTINGS.DELETE.BUTTON')
              "
              @click="removeHotel(hotel)"
            />
          </div>
        </div>

        <div class="flex flex-col gap-2">
          <span class="text-sm text-n-slate-11">
            {{ t('HOTELS_SETTINGS.AGENTS_LABEL') }}
          </span>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="agent in agentList"
              :key="agent.id"
              type="button"
              class="px-3 py-1 rounded-full text-sm border transition-colors cursor-pointer"
              :class="
                isAssigned(hotel, agent.id)
                  ? 'bg-n-brand/15 border-n-brand text-n-blue-11'
                  : 'bg-transparent border-n-strong text-n-slate-11 hover:border-n-slate-8'
              "
              @click="toggleAgent(hotel, agent.id)"
            >
              {{ agent.name }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
