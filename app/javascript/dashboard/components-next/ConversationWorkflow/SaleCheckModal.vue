<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import HotelsAPI from 'dashboard/api/hotels';

const emit = defineEmits(['submit', 'skip', 'close']);

const { t } = useI18n();

const dialogRef = ref(null);
const conversationContext = ref(null);
const choice = ref(null);
const saleValue = ref('');
const hotelId = ref(null);
const hotels = ref([]);

const hotelOptions = computed(() =>
  hotels.value.map(hotel => ({ value: hotel.id, label: hotel.name }))
);

const isFormComplete = computed(() => {
  if (choice.value === false) return true;
  if (choice.value === true) {
    return !!hotelId.value && Number(saleValue.value) > 0;
  }
  return false;
});

const loadHotels = async () => {
  try {
    const { data } = await HotelsAPI.get();
    hotels.value = data;
  } catch (error) {
    hotels.value = [];
  }
};

const open = context => {
  conversationContext.value = context;
  choice.value = null;
  saleValue.value = '';
  hotelId.value = null;
  loadHotels();
  dialogRef.value?.open();
};

const close = () => dialogRef.value?.close();

const handleConfirm = () => {
  if (!isFormComplete.value) return;
  if (choice.value === true && !hotels.value.length) {
    useAlert(t('CONVERSATION.SALE_CHECK.NO_HOTELS'));
    return;
  }
  emit('submit', {
    closed: choice.value,
    value: choice.value ? Number(saleValue.value) : 0,
    hotelId: choice.value ? hotelId.value : null,
    context: conversationContext.value,
  });
  close();
};

const handleSkip = () => {
  emit('skip', { context: conversationContext.value });
  close();
};

const handleClose = () => {
  conversationContext.value = null;
  emit('close');
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="lg"
    :title="t('CONVERSATION.SALE_CHECK.TITLE')"
    :description="t('CONVERSATION.SALE_CHECK.DESCRIPTION')"
    :confirm-button-label="t('CONVERSATION.SALE_CHECK.CONFIRM')"
    :cancel-button-label="t('CONVERSATION.SALE_CHECK.CANCEL')"
    :disable-confirm-button="!isFormComplete"
    @confirm="handleConfirm"
    @close="handleClose"
  >
    <div class="flex flex-col gap-4">
      <div class="flex gap-3">
        <Button
          :label="t('CONVERSATION.SALE_CHECK.CLOSED')"
          :color="choice === true ? 'teal' : 'slate'"
          :variant="choice === true ? 'solid' : 'outline'"
          icon="i-lucide-badge-check"
          class="flex-1"
          @click="choice = true"
        />
        <Button
          :label="t('CONVERSATION.SALE_CHECK.LOST')"
          :color="choice === false ? 'ruby' : 'slate'"
          :variant="choice === false ? 'solid' : 'outline'"
          icon="i-lucide-badge-x"
          class="flex-1"
          @click="choice = false"
        />
      </div>

      <template v-if="choice === true">
        <div class="flex flex-col gap-2">
          <label class="mb-0.5 text-sm font-medium text-n-slate-12">
            {{ t('CONVERSATION.SALE_CHECK.HOTEL_LABEL') }}
          </label>
          <ComboBox
            v-model="hotelId"
            :options="hotelOptions"
            :placeholder="t('CONVERSATION.SALE_CHECK.HOTEL_PLACEHOLDER')"
            class="w-full"
          />
          <p v-if="!hotelOptions.length" class="text-sm text-n-ruby-11">
            {{ t('CONVERSATION.SALE_CHECK.NO_HOTELS') }}
          </p>
        </div>
        <div class="flex flex-col gap-2">
          <label class="mb-0.5 text-sm font-medium text-n-slate-12">
            {{ t('CONVERSATION.SALE_CHECK.VALUE_LABEL') }}
          </label>
          <Input
            v-model="saleValue"
            type="number"
            min="0"
            step="0.01"
            size="md"
            :placeholder="t('CONVERSATION.SALE_CHECK.VALUE_PLACEHOLDER')"
          />
        </div>
      </template>

      <button
        type="button"
        class="self-start text-sm text-n-slate-11 hover:text-n-slate-12 underline bg-transparent border-0 p-0 cursor-pointer"
        @click="handleSkip"
      >
        {{ t('CONVERSATION.SALE_CHECK.SKIP') }}
      </button>
    </div>
  </Dialog>
</template>
