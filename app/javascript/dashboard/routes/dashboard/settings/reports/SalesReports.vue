<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SalesAPI from 'dashboard/api/sales';
import Spinner from 'shared/components/Spinner.vue';

const { t } = useI18n();

const RANGE_OPTIONS = [7, 30, 90];

const rangeDays = ref(30);
const isLoading = ref(false);
const summary = ref(null);

const currency = new Intl.NumberFormat('pt-BR', {
  style: 'currency',
  currency: 'BRL',
});

const formatValue = value => currency.format(value || 0);

const conversionRate = computed(() => {
  if (!summary.value) return 0;
  const total = summary.value.closed_count + summary.value.lost_count;
  if (!total) return 0;
  return Math.round((summary.value.closed_count / total) * 100);
});

const maxHotelValue = computed(() => {
  const rows = summary.value?.by_hotel || [];
  return rows.reduce((max, row) => Math.max(max, row.value), 0);
});

const barWidth = value => {
  if (!maxHotelValue.value) return 0;
  return Math.max(4, Math.round((value / maxHotelValue.value) * 100));
};

const fetchSummary = async () => {
  isLoading.value = true;
  try {
    const since = new Date();
    since.setDate(since.getDate() - rangeDays.value);
    const { data } = await SalesAPI.summary({
      since: since.toISOString().slice(0, 10),
    });
    summary.value = data;
  } catch (error) {
    useAlert(t('SALES_REPORTS.FETCH_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const setRange = days => {
  rangeDays.value = days;
  fetchSummary();
};

const formatDate = value =>
  new Date(value).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  });

onMounted(fetchSummary);
</script>

<template>
  <div class="flex flex-col gap-6 p-6 w-full overflow-y-auto">
    <div class="flex items-center justify-between flex-wrap gap-3">
      <div>
        <h1 class="text-xl font-medium text-n-slate-12">
          {{ t('SALES_REPORTS.HEADER') }}
        </h1>
        <p class="text-sm text-n-slate-11">
          {{ t('SALES_REPORTS.DESCRIPTION') }}
        </p>
      </div>
      <div class="flex gap-1 p-1 rounded-lg bg-n-solid-2 border border-n-weak">
        <button
          v-for="days in RANGE_OPTIONS"
          :key="days"
          type="button"
          class="px-3 py-1.5 text-sm rounded-md transition-colors cursor-pointer border-0"
          :class="
            rangeDays === days
              ? 'bg-n-brand text-n-black font-medium'
              : 'bg-transparent text-n-slate-11 hover:text-n-slate-12'
          "
          @click="setRange(days)"
        >
          {{ t('SALES_REPORTS.RANGE_DAYS', { days }) }}
        </button>
      </div>
    </div>

    <div v-if="isLoading" class="flex justify-center py-16">
      <Spinner />
    </div>

    <template v-else-if="summary">
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="flex flex-col gap-1 p-4 rounded-xl border border-n-weak bg-n-solid-2">
          <span class="flex items-center gap-2 text-sm text-n-slate-11">
            <span class="size-2 rounded-full bg-n-teal-9" />
            {{ t('SALES_REPORTS.TILES.CLOSED') }}
          </span>
          <span class="text-2xl font-semibold text-n-slate-12 tabular-nums">
            {{ summary.closed_count }}
          </span>
        </div>
        <div class="flex flex-col gap-1 p-4 rounded-xl border border-n-weak bg-n-solid-2">
          <span class="flex items-center gap-2 text-sm text-n-slate-11">
            <span class="size-2 rounded-full bg-n-ruby-9" />
            {{ t('SALES_REPORTS.TILES.LOST') }}
          </span>
          <span class="text-2xl font-semibold text-n-slate-12 tabular-nums">
            {{ summary.lost_count }}
          </span>
        </div>
        <div class="flex flex-col gap-1 p-4 rounded-xl border border-n-weak bg-n-solid-2">
          <span class="text-sm text-n-slate-11">
            {{ t('SALES_REPORTS.TILES.CONVERSION') }}
          </span>
          <span class="text-2xl font-semibold text-n-slate-12 tabular-nums">
            {{ conversionRate }}%
          </span>
        </div>
        <div class="flex flex-col gap-1 p-4 rounded-xl border border-n-weak bg-n-solid-2">
          <span class="text-sm text-n-slate-11">
            {{ t('SALES_REPORTS.TILES.TOTAL_VALUE') }}
          </span>
          <span class="text-2xl font-semibold text-n-slate-12 tabular-nums">
            {{ formatValue(summary.total_value) }}
          </span>
        </div>
      </div>

      <div class="grid lg:grid-cols-2 gap-4">
        <div class="flex flex-col gap-3 p-4 rounded-xl border border-n-weak bg-n-solid-2">
          <h2 class="text-base font-medium text-n-slate-12">
            {{ t('SALES_REPORTS.BY_HOTEL.TITLE') }}
          </h2>
          <p v-if="!summary.by_hotel.length" class="text-sm text-n-slate-11">
            {{ t('SALES_REPORTS.EMPTY') }}
          </p>
          <div v-else class="flex flex-col gap-3">
            <div
              v-for="row in summary.by_hotel"
              :key="row.id"
              class="flex flex-col gap-1"
            >
              <div class="flex justify-between text-sm">
                <span class="text-n-slate-12">{{ row.name }}</span>
                <span class="text-n-slate-11 tabular-nums">
                  {{ t('SALES_REPORTS.BY_HOTEL.SALES', { count: row.count }) }}
                  · {{ formatValue(row.value) }}
                </span>
              </div>
              <div class="h-2 rounded-full bg-n-alpha-black2 overflow-hidden">
                <div
                  class="h-full rounded-full bg-n-brand"
                  :style="{ width: `${barWidth(row.value)}%` }"
                />
              </div>
            </div>
          </div>
        </div>

        <div class="flex flex-col gap-3 p-4 rounded-xl border border-n-weak bg-n-solid-2">
          <h2 class="text-base font-medium text-n-slate-12">
            {{ t('SALES_REPORTS.BY_AGENT.TITLE') }}
          </h2>
          <p v-if="!summary.by_agent.length" class="text-sm text-n-slate-11">
            {{ t('SALES_REPORTS.EMPTY') }}
          </p>
          <table v-else class="w-full text-sm">
            <thead>
              <tr class="text-left text-n-slate-11">
                <th class="py-1.5 font-normal">
                  {{ t('SALES_REPORTS.BY_AGENT.AGENT') }}
                </th>
                <th class="py-1.5 font-normal text-right">
                  {{ t('SALES_REPORTS.BY_AGENT.COUNT') }}
                </th>
                <th class="py-1.5 font-normal text-right">
                  {{ t('SALES_REPORTS.BY_AGENT.VALUE') }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="row in summary.by_agent"
                :key="row.id"
                class="border-t border-n-weak"
              >
                <td class="py-2 text-n-slate-12">{{ row.name }}</td>
                <td class="py-2 text-right text-n-slate-12 tabular-nums">
                  {{ row.count }}
                </td>
                <td class="py-2 text-right text-n-slate-12 tabular-nums">
                  {{ formatValue(row.value) }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div class="flex flex-col gap-3 p-4 rounded-xl border border-n-weak bg-n-solid-2">
        <h2 class="text-base font-medium text-n-slate-12">
          {{ t('SALES_REPORTS.RECENT.TITLE') }}
        </h2>
        <p v-if="!summary.recent.length" class="text-sm text-n-slate-11">
          {{ t('SALES_REPORTS.EMPTY') }}
        </p>
        <div v-else class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="text-left text-n-slate-11">
                <th class="py-1.5 font-normal">
                  {{ t('SALES_REPORTS.RECENT.DATE') }}
                </th>
                <th class="py-1.5 font-normal">
                  {{ t('SALES_REPORTS.RECENT.CONTACT') }}
                </th>
                <th class="py-1.5 font-normal">
                  {{ t('SALES_REPORTS.RECENT.HOTEL') }}
                </th>
                <th class="py-1.5 font-normal">
                  {{ t('SALES_REPORTS.RECENT.AGENT') }}
                </th>
                <th class="py-1.5 font-normal text-right">
                  {{ t('SALES_REPORTS.RECENT.VALUE') }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="sale in summary.recent"
                :key="sale.id"
                class="border-t border-n-weak"
              >
                <td class="py-2 text-n-slate-11 tabular-nums">
                  {{ formatDate(sale.created_at) }}
                </td>
                <td class="py-2 text-n-slate-12">{{ sale.contact || '-' }}</td>
                <td class="py-2 text-n-slate-12">{{ sale.hotel || '-' }}</td>
                <td class="py-2 text-n-slate-12">{{ sale.agent || '-' }}</td>
                <td class="py-2 text-right font-medium text-n-slate-12 tabular-nums">
                  {{ formatValue(sale.value) }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </template>
  </div>
</template>
